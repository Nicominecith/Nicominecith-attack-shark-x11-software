import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 980; height: 760; visible: true
    title: Theme.brand + " X11"
    color: Theme.bg
    readonly property bool wide: width > 760

    component Toggle: RowLayout {
        id: t
        property string label; property bool value; signal flipped(bool v)
        Layout.fillWidth: true
        Text { text: t.label; color: Theme.text; font.pixelSize: 15; Layout.fillWidth: true }
        Rectangle {
            width: 56; height: 30; radius: 4; color: t.value ? Theme.accent : Theme.panelHi; border.color: Theme.line
            Rectangle { width: 22; height: 22; radius: 3; y: 4; x: t.value ? 30 : 4; color: t.value ? "#04130A" : Theme.dim
                        Behavior on x { NumberAnimation { duration: 120 } } }
            MouseArea { anchors.fill: parent; onClicked: t.flipped(!t.value) }
        }
    }
    component Slide: ColumnLayout {
        id: s
        property string label; property alias from: sl.from; property alias to: sl.to
        property alias value: sl.value; property string unit: ""; property alias step: sl.stepSize
        signal moved(int v)
        Layout.fillWidth: true; spacing: 2
        RowLayout { Text { text: s.label; color: Theme.text; font.pixelSize: 15; Layout.fillWidth: true }
                    Text { text: Math.round(sl.value) + " " + s.unit; color: Theme.accent; font.pixelSize: 15; font.bold: true } }
        Slider { id: sl; Layout.fillWidth: true; snapMode: Slider.SnapAlways; onMoved: s.moved(Math.round(value))
            background: Rectangle { y: sl.height/2 - 2; width: sl.width; height: 4; color: Theme.panelHi
                Rectangle { width: sl.visualPosition * parent.width; height: 4; color: Theme.accent } }
            handle: Rectangle { x: sl.visualPosition * (sl.width - 20); y: sl.height/2 - 10; width: 20; height: 20; radius: 3; color: Theme.text } }
    }

    Flickable {
        anchors.fill: parent; contentWidth: width; contentHeight: page.implicitHeight + 40
        clip: true; boundsBehavior: Flickable.StopAtBounds
        ColumnLayout {
            id: page
            x: 16; y: 12; width: parent.width - 32; spacing: 14

            // ---- Header / Branding ----
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Item { width: 44; height: 44   // Würfel-Logo
                    Rectangle { x: 6; y: 6; width: 32; height: 32; color: Theme.accent }
                    Rectangle { x: 6; y: 6; width: 32; height: 10; color: "#9BFFC4" }
                    Rectangle { x: 26; y: 16; width: 12; height: 22; color: Theme.accent2 }
                    Rectangle { x: 14; y: 22; width: 6; height: 6; color: "#04130A" } }
                ColumnLayout { spacing: 0
                    Text { text: Theme.brand; color: Theme.text; font.pixelSize: 24; font.bold: true; font.letterSpacing: 4 }
                    Text { text: Theme.tagline; color: Theme.dim; font.pixelSize: 12 } }
                Item { Layout.fillWidth: true }
                Rectangle { // Verbindungs-Badge
                    implicitWidth: st.implicitWidth + 28; height: 32; radius: 4; color: Theme.panel
                    border.color: dev.connected ? Theme.accent : Theme.line
                    Text { id: st; anchors.centerIn: parent; text: dev.status; font.pixelSize: 12
                           color: dev.connected ? Theme.accent : Theme.warn }
                    MouseArea { anchors.fill: parent; onClicked: dev.refresh() } }
            }

            // ---- Hero: Maus + Akku ----
            Card {
                title: "Gerät"
                RowLayout { Layout.fillWidth: true; spacing: 20
                    Image { source: "../assets/mouse.png"; Layout.preferredHeight: 130; Layout.preferredWidth: 130
                            fillMode: Image.PreserveAspectFit; opacity: dev.connected ? 1 : 0.35 }
                    ColumnLayout { Layout.fillWidth: true; spacing: 8
                        Text { text: "Attack Shark X11"; color: Theme.text; font.pixelSize: 20; font.bold: true }
                        Text { color: Theme.dim; font.pixelSize: 13
                               text: dev.battery >= 0 ? "Akku " + dev.battery + " %" : dev.battery === -2 ? "Lädt / Kabelbetrieb" : "Akku unbekannt" }
                        Rectangle { Layout.fillWidth: true; height: 12; color: Theme.panelHi; radius: 2
                            Rectangle { height: parent.height; radius: 2; width: parent.width * Math.max(0, dev.battery) / 100
                                color: dev.battery >= 0 && dev.battery < 20 ? Theme.bad : Theme.accent
                                Behavior on width { NumberAnimation { duration: 400 } } } } } }
            }

            GridLayout {
                Layout.fillWidth: true; columns: win.wide ? 2 : 1; columnSpacing: 14; rowSpacing: 14

                Card { title: "Polling Rate"; Layout.alignment: Qt.AlignTop
                    Seg { model: ["125", "250", "500", "1000"]; current: dev.pollingIdx; onPicked: i => dev.pollingIdx = i }
                    Text { text: "Hz – höher = flüssiger, etwas mehr Akkuverbrauch"; color: Theme.dim; font.pixelSize: 12 } }

                Card { title: "LED-Modus"; Layout.alignment: Qt.AlignTop
                    Seg { model: Theme.ledNames; current: dev.colorMode; onPicked: i => dev.colorMode = i }
                    Rectangle { Layout.fillWidth: true; height: 6; color: Theme.ledColors[dev.colorMode]; radius: 2 } }

                Card { title: "Sensor"; Layout.alignment: Qt.AlignTop
                    Toggle { label: "Angle Snapping"; value: dev.angleSnap; onFlipped: v => dev.angleSnap = v }
                    Toggle { label: "Ripple Control"; value: dev.ripple; onFlipped: v => dev.ripple = v }
                    Slide { label: "Tastenreaktionszeit"; from: 4; to: 50; step: 2; unit: "ms"; value: dev.keyResp; onMoved: v => dev.keyResp = v } }

                Card { title: "Energie"; Layout.alignment: Qt.AlignTop
                    Slide { label: "Standby nach"; from: 1; to: 30; step: 1; unit: "min"; value: dev.sleepTime; onMoved: v => dev.sleepTime = v }
                    Slide { label: "Tiefschlaf nach"; from: 1; to: 60; step: 1; unit: "min"; value: dev.deepSleep; onMoved: v => dev.deepSleep = v } }
            }

            Card { title: "Profile"
                RowLayout { Layout.fillWidth: true; spacing: 8
                    Repeater { model: 3
                        delegate: ColumnLayout { required property int index; Layout.fillWidth: true; spacing: 6
                            Rectangle { Layout.fillWidth: true; height: 40; radius: 4; color: Theme.panelHi; border.color: Theme.accent2
                                Text { anchors.centerIn: parent; text: "Laden " + (index + 1); color: Theme.text; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: dev.loadProfile(index) } }
                            Rectangle { Layout.fillWidth: true; height: 34; radius: 4; color: "transparent"; border.color: Theme.line
                                Text { anchors.centerIn: parent; text: "Speichern"; color: Theme.dim; font.pixelSize: 12 }
                                MouseArea { anchors.fill: parent; onClicked: dev.saveProfile(index) } } } } } }

            // ---- Anwenden ----
            Rectangle {
                Layout.fillWidth: true; height: 56; radius: 4
                color: dev.busy ? Theme.panelHi : Theme.accent
                Text { anchors.centerIn: parent; text: dev.busy ? "…" : "ÜBERNEHMEN"; font.pixelSize: 17; font.bold: true
                       font.letterSpacing: 3; color: dev.busy ? Theme.dim : "#04130A" }
                MouseArea { anchors.fill: parent; enabled: !dev.busy; onClicked: dev.apply() }
            }
            Text { text: "Inoffizielle Community-Software · nicht mit Attack Shark verbunden"; color: Theme.dim
                   font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
        }
    }
}
