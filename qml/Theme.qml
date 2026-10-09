pragma Singleton
import QtQuick

// Nicominecith-Look: alles Farbige und das Branding steckt hier.
QtObject {
    readonly property string brand: "NICOMINECITH"
    readonly property string tagline: "X11 Control · Nicominecith Edition"
    readonly property color bg: "#070A0D"
    readonly property color panel: "#0E1419"
    readonly property color panelHi: "#151D25"
    readonly property color line: "#1F2B35"
    readonly property color accent: "#3DFF8B"   // Nico-Grün
    readonly property color accent2: "#8B5CFF"  // Violett
    readonly property color text: "#E8F1F2"
    readonly property color dim: "#7F93A0"
    readonly property color warn: "#FFB84D"
    readonly property color bad: "#FF5C7A"
    readonly property int radius: 4              // bewusst kantig, Block-Optik
    readonly property var ledNames: ["Aus", "Farbe 1", "Farbe 2", "Farbe 3"]
    readonly property var ledColors: ["#333B42", "#3DFF8B", "#8B5CFF", "#FF5C7A"]
}
