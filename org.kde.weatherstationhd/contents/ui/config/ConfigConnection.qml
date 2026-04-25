import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Configuration page: API connection settings
// property alias cfg_<name> binds automatically to plasmoid.configuration.<name>
// Plasma saves these when the user clicks OK.

Kirigami.FormLayout {
    id: connectionPage

    // ── Automatic bindings via cfg_ prefix ───────────────────────────────
    property alias cfg_apiKey:         apiKeyField.text
    property alias cfg_updateInterval: intervalSpinBox.value

    // Lat/Lon as strings (DoubleValidator ensures numeric input)
    property double cfg_latitude:  52.2994031
    property double cfg_longitude: 13.60879554

    // Language + units need manual sync (ComboBox index ≠ string value)
    property string cfg_language:  "de-DE"
    property string cfg_units:     "m"
    property alias  cfg_showClock: showClockCheck.checked

    // ── API Key ───────────────────────────────────────────────────────────
    QQC2.TextField {
        id:                  apiKeyField
        Kirigami.FormData.label: i18n("API-Schlüssel:")
        placeholderText:     i18n("Visual Crossing API-Schlüssel eingeben")
        echoMode:            TextInput.Password
        Layout.fillWidth:    true
    }

    // ── Coordinates ───────────────────────────────────────────────────────
    QQC2.TextField {
        id:                  latField
        Kirigami.FormData.label: i18n("Breitengrad:")
        text:                connectionPage.cfg_latitude.toFixed(6)
        placeholderText:     "z.B. 52.299403"
        inputMethodHints:    Qt.ImhFormattedNumbersOnly
        validator:           DoubleValidator { bottom: -90; top: 90; decimals: 6; locale: "C" }
        Layout.fillWidth:    true
        onEditingFinished: {
            if (acceptableInput) connectionPage.cfg_latitude = parseFloat(text)
        }
    }

    QQC2.TextField {
        id:                  lonField
        Kirigami.FormData.label: i18n("Längengrad:")
        text:                connectionPage.cfg_longitude.toFixed(6)
        placeholderText:     "z.B. 13.608795"
        inputMethodHints:    Qt.ImhFormattedNumbersOnly
        validator:           DoubleValidator { bottom: -180; top: 180; decimals: 6; locale: "C" }
        Layout.fillWidth:    true
        onEditingFinished: {
            if (acceptableInput) connectionPage.cfg_longitude = parseFloat(text)
        }
    }

    // Hint for finding coordinates — URL is clickable
    RowLayout {
        Kirigami.FormData.label: ""
        spacing: 4

        Text {
            text:           i18n("Koordinaten ermitteln:")
            color:          Kirigami.Theme.disabledTextColor
            font.pixelSize: Kirigami.Units.gridUnit * 0.72
        }
        Text {
            text:           "mapcoordinates.net"
            color:          Kirigami.Theme.linkColor
            font.pixelSize: Kirigami.Units.gridUnit * 0.72
            font.underline: true
            TapHandler {
                onTapped:    Qt.openUrlExternally("https://www.mapcoordinates.net")
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    // ── Language ──────────────────────────────────────────────────────────
    QQC2.ComboBox {
        id:                  languageCombo
        Kirigami.FormData.label: i18n("Sprache:")
        model:               ["de-DE", "en-US", "fr-FR", "es-ES", "it-IT",
                              "nl-NL", "pl-PL", "pt-BR", "ru-RU", "zh-CN"]
        currentIndex:        model.indexOf(connectionPage.cfg_language)
        onActivated:         connectionPage.cfg_language = currentText
        Component.onCompleted: {
            var idx = model.indexOf(connectionPage.cfg_language)
            currentIndex = idx >= 0 ? idx : 0
        }
    }

    // ── Units ─────────────────────────────────────────────────────────────
    QQC2.ComboBox {
        id:                  unitsCombo
        Kirigami.FormData.label: i18n("Einheiten:")
        textRole:            "text"
        valueRole:           "value"
        model: [
            { text: i18n("Metrisch  (°C, km/h, hPa, km)"), value: "m" },
            { text: i18n("Imperial  (°F, mph, inHg, mi)"),  value: "e" },
            { text: i18n("Hybrid    (°C, mph, hPa, km)"),   value: "h" }
        ]
        Component.onCompleted: {
            currentIndex = indexOfValue(connectionPage.cfg_units)
            if (currentIndex < 0) currentIndex = 0
        }
        onActivated: connectionPage.cfg_units = currentValue
    }

    // ── Display options ───────────────────────────────────────────────────
    QQC2.CheckBox {
        id:                  showClockCheck
        Kirigami.FormData.label: i18n("Anzeige:")
        text:                i18n("Uhrzeit anzeigen")
    }

    // ── Update interval ───────────────────────────────────────────────────
    QQC2.SpinBox {
        id:                  intervalSpinBox
        Kirigami.FormData.label: i18n("Aktualisierung (Sekunden):")
        from:                60
        to:                  3600
        stepSize:            60
        editable:            true
    }
}
