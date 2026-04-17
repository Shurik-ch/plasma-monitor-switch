#!/usr/bin/env python3
"""DDC/CI helper for Monitor Switch plasmoid — outputs JSON."""
import subprocess, json, sys, re

def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True, shell=True)
    return r.stdout.strip(), r.returncode

def detect_displays():
    out, rc = run("ddcutil detect 2>/dev/null")
    if rc != 0 or not out:
        return []
    displays = []
    cur = None
    for line in out.splitlines():
        m = re.match(r'^Display (\d+)', line)
        if m:
            if cur:
                displays.append(cur)
            cur = {"num": int(m.group(1)), "model": "", "mfg": ""}
        elif cur:
            m2 = re.search(r'Model:\s+(.+)', line)
            if m2:
                cur["model"] = m2.group(1).strip()
            m3 = re.search(r'Mfg id:\s+(.+)', line)
            if m3:
                cur["mfg"] = m3.group(1).strip()
    if cur:
        displays.append(cur)
    return displays

def get_inputs(display_num):
    out, _ = run(f"ddcutil capabilities --display {display_num} 2>/dev/null")
    inputs = []
    in_60 = False
    in_values = False
    for line in out.splitlines():
        if re.match(r'\s+Feature: 60\b', line):
            in_60 = True
            in_values = False
        elif in_60 and re.match(r'\s+Values:', line):
            in_values = True
        elif in_60 and in_values:
            m = re.match(r'\s{8,}([0-9a-fA-F]+):\s*(.+)', line)
            if m:
                hex_val = m.group(1).lower()
                name = m.group(2).strip()
                if name == "Unrecognized value":
                    name = f"Input 0x{hex_val}"
                inputs.append({"value": f"0x{hex_val}", "name": name})
            elif re.match(r'\s+Feature:', line):
                break
    return inputs

def get_current(display_num):
    out, _ = run(f"ddcutil getvcp 60 --display {display_num} --brief 2>/dev/null")
    m = re.search(r'x([0-9a-fA-F]+)\s*$', out)
    return f"0x{m.group(1).lower()}" if m else None

def cmd_list():
    displays = detect_displays()
    for d in displays:
        d["inputs"] = get_inputs(d["num"])
        d["current"] = get_current(d["num"])
    print(json.dumps(displays))

def cmd_current(display_num):
    print(json.dumps({"current": get_current(display_num)}))

def cmd_switch(display_num, value):
    _, rc = run(f"ddcutil setvcp 60 {value} --display {display_num} 2>/dev/null")
    print(json.dumps({"success": rc == 0}))

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    if cmd == "list":
        cmd_list()
    elif cmd == "current" and len(sys.argv) >= 3:
        cmd_current(int(sys.argv[2]))
    elif cmd == "switch" and len(sys.argv) >= 4:
        cmd_switch(int(sys.argv[2]), sys.argv[3])
    else:
        print(json.dumps([]))
