import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls

Kirigami.FormLayout {
    id: appearancePage

    property string cfg_bgColor: "#1a1a2e"
    property double cfg_bgAlpha: 0.85

    // ── Vorschau ──────────────────────────────────────────────────────────
    Rectangle {
        Kirigami.FormData.label: i18n("Vorschau:")
        width:  Kirigami.Units.gridUnit * 12
        height: Kirigami.Units.gridUnit * 3
        radius: Kirigami.Units.cornerRadius
        color:  _bgColor()

        Text {
            anchors.centerIn: parent
            text:  "Weather Widget KDE"
            color: "white"
            font.pixelSize: Kirigami.Units.gridUnit * 0.8
        }
    }

    // ── Hintergrund ───────────────────────────────────────────────────────
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Hintergrund")
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Farbe:")
        spacing: Kirigami.Units.smallSpacing

        KQuickControls.ColorButton {
            id: bgColorButton
            color: appearancePage.cfg_bgColor
            showAlphaChannel: false
            onColorChanged: {
                var hex = color.toString()
                appearancePage.cfg_bgColor = (hex.length === 9)
                    ? "#" + hex.substring(3)
                    : hex.substring(0, 7).toUpperCase()
            }
        }

        Text {
            text:  appearancePage.cfg_bgColor
            color: Kirigami.Theme.textColor
            font.family: "monospace"
            font.pixelSize: Kirigami.Units.gridUnit * 0.82
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Deckkraft:")
        spacing: Kirigami.Units.smallSpacing

        QQC2.Slider {
            id: bgAlphaSlider
            from: 0.0; to: 1.0; stepSize: 0.01
            value: appearancePage.cfg_bgAlpha
            implicitWidth: Kirigami.Units.gridUnit * 10
            onMoved: appearancePage.cfg_bgAlpha = Math.round(value * 100) / 100
        }

        Text {
            text:  Math.round(bgAlphaSlider.value * 100) + " %"
            color: Kirigami.Theme.textColor
            Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
        }
    }

    function _bgColor() {
        var c = Qt.color(appearancePage.cfg_bgColor)
        return Qt.rgba(c.r, c.g, c.b, appearancePage.cfg_bgAlpha)
    }
}
