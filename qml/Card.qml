import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string title: ""
    default property alias content: col.data
    color: Theme.panel; radius: Theme.radius
    border.color: Theme.line; border.width: 1
    implicitHeight: col.implicitHeight + 32
    Layout.fillWidth: true
    Rectangle { width: 3; height: 18; x: 0; y: 16; color: Theme.accent }
    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 12
        Text { text: root.title.toUpperCase(); color: Theme.dim; font.pixelSize: 12; font.letterSpacing: 2; font.bold: true }
    }
}
