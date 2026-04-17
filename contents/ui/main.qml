import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    toolTipMainText: "Monitor Switch"
    toolTipSubText: displays.length > 0 ? displays[0].model : "DDC/CI Monitor Control"

    property var displays: []
    property bool loading: false
    property bool capsLoaded: false
    property var customNames: ({})
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/helper.py")
                                           .toString().replace("file://", "")

    Connections {
        target: Plasmoid.configuration
        function onCustomNamesChanged() {
            try { root.customNames = JSON.parse(Plasmoid.configuration.customNames) }
            catch(e) { root.customNames = {} }
        }
    }

    function displayName(input) {
        return customNames[input.value] || input.name
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            const stdout = (data["stdout"] || "").trim()
            disconnectSource(sourceName)

            if (/ list$/.test(sourceName)) {
                root.loading = false
                try {
                    root.displays = JSON.parse(stdout)
                    root.capsLoaded = true
                } catch(e) {
                    console.error("MonitorSwitch: parse error:", e, stdout)
                }
            } else if (/ current \d+$/.test(sourceName)) {
                try {
                    const res = JSON.parse(stdout)
                    const num = parseInt(sourceName.split(" ").pop())
                    root.displays = root.displays.map(d =>
                        d.num === num ? Object.assign({}, d, { current: res.current }) : d
                    )
                } catch(e) {}
            }
        }

        function exec(cmd) { connectSource(cmd) }
    }

    function loadAll() {
        loading = true
        executable.exec("python3 " + scriptPath + " list")
    }

    function refreshCurrent() {
        displays.forEach(d =>
            executable.exec("python3 " + scriptPath + " current " + d.num)
        )
    }

    function switchInput(displayNum, value) {
        root.displays = root.displays.map(d =>
            d.num === displayNum ? Object.assign({}, d, { current: value }) : d
        )
        executable.exec("python3 " + scriptPath + " switch " + displayNum + " " + value)
    }

    onExpandedChanged: () => {
        if (root.expanded) {
            capsLoaded ? refreshCurrent() : loadAll()
        }
    }

    Component.onCompleted: {
        try { customNames = JSON.parse(Plasmoid.configuration.customNames) } catch(e) {}
        loadAll()
    }

    compactRepresentation: Item {
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.85
            height: width
            source: "video-display"
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.margins: Kirigami.Units.smallSpacing

        PlasmaComponents.BusyIndicator {
            visible: root.loading
            running: root.loading
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
        }

        Repeater {
            model: root.displays
            delegate: ColumnLayout {
                id: dispItem
                required property var modelData
                required property int index
                spacing: Kirigami.Units.smallSpacing
                Layout.fillWidth: true

                Kirigami.Heading {
                    text: dispItem.modelData.model || ("Display " + dispItem.modelData.num)
                    level: 3
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Repeater {
                    model: dispItem.modelData.inputs
                    delegate: PlasmaComponents.Button {
                        id: inputBtn
                        required property var modelData
                        readonly property bool isCurrent: dispItem.modelData.current === inputBtn.modelData.value
                        readonly property string inputName: inputBtn.modelData.name.toLowerCase()

                        text: root.displayName(inputBtn.modelData)
                        icon.name: inputName.includes("displayport") || inputName.includes(" dp") ? "video-display"
                                 : inputName.includes("hdmi")                                     ? "video-display"
                                 : inputName.includes("vga")                                      ? "video-display"
                                 : "computer-laptop"
                        Layout.fillWidth: true
                        highlighted: isCurrent
                        flat: !isCurrent

                        onClicked: {
                            root.switchInput(dispItem.modelData.num, inputBtn.modelData.value)
                            root.expanded = false
                        }
                    }
                }

                Kirigami.Separator {
                    visible: dispItem.index < root.displays.length - 1
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents.Button {
                text: "Refresh"
                icon.name: "view-refresh"
                flat: true
                Layout.fillWidth: true
                onClicked: root.loadAll()
            }
        }

        Kirigami.PlaceholderMessage {
            visible: !root.loading && root.displays.length === 0
            text: "No displays found"
            explanation: "Install ddcutil and configure i2c permissions"
            Layout.fillWidth: true
        }
    }
}
