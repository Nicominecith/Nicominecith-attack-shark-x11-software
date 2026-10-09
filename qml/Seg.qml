import QtQuick
import QtQuick.Layouts

// Segment-Auswahl (touchfreundlich)
RowLayout {
    id: root
    property var model: []
    property int current: 0
    signal picked(int index)
    spacing: 6
    Layout.fillWidth: true
    Repeater {
        model: root.model
        delegate: Rectangle {
            required property int index
            required property var modelData
            Layout.fillWidth: true; implicitHeight: 44; radius: Theme.radius
            color: root.current === index ? Theme.accent : Theme.panelHi
            border.color: root.current === index ? Theme.accent : Theme.line
            Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 14; font.bold: true
                   color: root.current === index ? "#04130A" : Theme.text }
            MouseArea { anchors.fill: parent; onClicked: root.picked(index) }
        }
    }
}
