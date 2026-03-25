import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "WeatherData.js" as WeatherData

PlasmoidItem {
    id: root

    // No Plasma frame — our own Rectangle provides the background
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // ── Configuration aliases ────────────────────────────────────────────
    readonly property string cfgApiKey:      plasmoid.configuration.apiKey
    readonly property double cfgLat:         plasmoid.configuration.latitude
    readonly property double cfgLon:         plasmoid.configuration.longitude
    readonly property string cfgLang:        plasmoid.configuration.language
    readonly property string cfgUnits:       plasmoid.configuration.units
    readonly property int    cfgInterval:    plasmoid.configuration.updateInterval

    // ── Weather data state ───────────────────────────────────────────────
    property var    weatherData:  null
    property bool   loading:      false
    property string errorMessage: ""

    // ── Plasma representations ───────────────────────────────────────────
    // On desktop (Planar): show full widget directly
    // In panel: show compact icon+temp, click to open popup
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
                             ? fullRepresentation
                             : compactRepresentation

    switchWidth:  Kirigami.Units.gridUnit * 10
    switchHeight: Kirigami.Units.gridUnit * 6

    compactRepresentation: CompactRepresentation {}
    fullRepresentation:    FullRepresentation    {}

    // ── Update timer ─────────────────────────────────────────────────────
    Timer {
        id: updateTimer
        interval:         root.cfgInterval * 1000
        running:          root.cfgApiKey.length > 0
        repeat:           true
        triggeredOnStart: true
        onTriggered:      root.refresh()
    }

    // Re-fetch when config changes (Qt.callLater deduplicates if multiple change at once)
    onCfgApiKeyChanged:   { updateTimer.restart(); Qt.callLater(refresh) }
    onCfgLatChanged:      Qt.callLater(refresh)
    onCfgLonChanged:      Qt.callLater(refresh)
    onCfgUnitsChanged:    Qt.callLater(refresh)
    onCfgLangChanged:     Qt.callLater(refresh)
    onCfgIntervalChanged: updateTimer.restart()

    // ── API fetch ────────────────────────────────────────────────────────
    function refresh() {
        if (cfgApiKey.length === 0) {
            errorMessage = qsTr("Bitte API-Schlüssel in den Einstellungen eintragen.")
            return
        }
        loading = true
        errorMessage = ""
        WeatherData.fetchWeather(
            {
                apiKey:    cfgApiKey,
                latitude:  cfgLat,
                longitude: cfgLon,
                units:     cfgUnits,
                language:  cfgLang
            },
            function(data, err) {
                loading = false
                if (err) {
                    errorMessage = err
                } else {
                    weatherData = data
                }
            }
        )
    }

    // ── Icon path helpers (used by all child components via root.*) ───────
    function weatherIconPath(code) {
        var safeCode = (code === null || code === undefined || code === "") ? "NA" : String(code)
        return Qt.resolvedUrl("../icons/" + safeCode + ".png")
    }

    function moonIconPath(code) {
        var safeCode = (code === null || code === undefined || code === "") ? "N" : String(code)
        return Qt.resolvedUrl("../icons/moon/" + safeCode + ".png")
    }

    // ── Panel tooltip ────────────────────────────────────────────────────
    // In Plasma 6: toolTipMainText/SubText are direct PlasmoidItem properties
    toolTipMainText: {
        if (!weatherData) return "Weather Widget KDE"
        var c = weatherData.current
        return (c.city ? c.city + " — " : "") +
               (c.temperature !== null ? c.temperature + c.tempUnit : "—")
    }
    toolTipSubText: {
        if (weatherData) return weatherData.current.condition
        if (errorMessage) return errorMessage
        return qsTr("Lade Wetterdaten…")
    }
    Plasmoid.icon: {
        if (weatherData) {
            var code = weatherData.current.iconCode
            return Qt.resolvedUrl("../icons/" + (code || "NA") + ".png")
        }
        return "weather-clear"
    }
}
