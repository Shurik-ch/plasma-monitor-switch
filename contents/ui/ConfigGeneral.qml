import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

Kirigami.Page {
    id: page
    title: "General"
    padding: Kirigami.Units.largeSpacing

    property string cfg_customNames: "{}"
    property string cfg_customNamesDefault: "{}"
    property var customNames: ({})
    property var inputs: []
    property bool loadingInputs: true
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/helper.py")
                                           .toString().replace("file://", "")

    SystemPalette { id: sysPalette; colorGroup: SystemPalette.Active }

    onCfg_customNamesChanged: {
        try { customNames = JSON.parse(cfg_customNames) } catch(e) { customNames = {} }
    }

    P5Support.DataSource {
        id: exe
        engine: "executable"
        connectedSources: []
        onNewData: (src, data) => {
            disconnectSource(src)
            try {
                const displays = JSON.parse((data["stdout"] || "").trim())
                const all = []
                displays.forEach(d => d.inputs.forEach(inp => all.push(inp)))
                page.inputs = all
            } catch(e) {}
            page.loadingInputs = false
        }
        function exec(cmd) { connectSource(cmd) }
    }

    Component.onCompleted: {
        try { customNames = JSON.parse(cfg_customNames) } catch(e) {}
        exe.exec("python3 " + scriptPath + " list")
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            text: "Custom input names"
            level: 4
            Layout.fillWidth: true
            color: sysPalette.windowText
        }

        PlasmaComponents.Label {
            text: "Leave blank to use the default name from the monitor."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            opacity: 0.7
            color: sysPalette.windowText
        }

        PlasmaComponents.BusyIndicator {
            visible: page.loadingInputs
            running: page.loadingInputs
            Layout.alignment: Qt.AlignHCenter
        }

        Repeater {
            model: page.inputs
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: modelData.name + ":"
                    color: sysPalette.windowText
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    elide: Text.ElideRight
                }

                QQC2.TextField {
                    Layout.fillWidth: true
                    color: sysPalette.text
                    placeholderText: modelData.name
                    text: page.customNames[modelData.value] || ""
                    background: Rectangle {
                        color: sysPalette.base
                        radius: 4
                        border.color: sysPalette.mid
                    }
                    onEditingFinished: {
                        const names = Object.assign({}, page.customNames)
                        if (text.trim()) {
                            names[modelData.value] = text.trim()
                        } else {
                            delete names[modelData.value]
                        }
                        page.customNames = names
                        page.cfg_customNames = JSON.stringify(names)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Kirigami.PlaceholderMessage {
            visible: !page.loadingInputs && page.inputs.length === 0
            text: "No inputs detected"
            explanation: "Make sure ddcutil is installed and i2c permissions are configured"
            Layout.fillWidth: true
        }
    }
}
