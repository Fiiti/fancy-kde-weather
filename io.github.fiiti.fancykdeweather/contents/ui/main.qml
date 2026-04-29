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
    readonly property bool   cfgShowClock:   plasmoid.configuration.showClock

    // ── Weather data state ───────────────────────────────────────────────
    property var    weatherData:    null
    property bool   loading:        false
    property string errorMessage:   ""
    property int    _retryCount:    0
    property int    retryCountdown: 0   // seconds until next retry (shown in overlay)

    // ── Plasma representations ───────────────────────────────────────────
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
                             ? fullRepresentation
                             : compactRepresentation

    switchWidth:  Kirigami.Units.gridUnit * 10
    switchHeight: Kirigami.Units.gridUnit * 6

    compactRepresentation: CompactRepresentation {}
    fullRepresentation:    FullRepresentation    {}

    // ── Scheduled update timer ───────────────────────────────────────────
    Timer {
        id: updateTimer
        interval:         root.cfgInterval * 1000
        running:          root.cfgApiKey.length > 0
        repeat:           true
        triggeredOnStart: true
        onTriggered:      root.refresh()
    }

    // ── Retry timer — fires after transient failures (no data yet) ────────
    // Schedule: 5 × 2 s, then 5 × 5 s, then give up and let updateTimer handle it
    Timer {
        id: retryTimer
        repeat: false
        onTriggered: root.refresh()
    }

    // ── Countdown tick for UI display ────────────────────────────────────
    Timer {
        id: countdownTimer
        interval: 1000
        repeat:   true
        onTriggered: {
            if (root.retryCountdown > 0) root.retryCountdown -= 1
            else stop()
        }
    }

    // Re-fetch when config changes (Qt.callLater deduplicates multiple simultaneous changes)
    onCfgApiKeyChanged:   { updateTimer.restart(); Qt.callLater(refresh) }
    onCfgLatChanged:      Qt.callLater(refresh)
    onCfgLonChanged:      Qt.callLater(refresh)
    onCfgUnitsChanged:    Qt.callLater(refresh)
    onCfgLangChanged:     Qt.callLater(refresh)
    onCfgIntervalChanged: updateTimer.restart()

    // ── API fetch ────────────────────────────────────────────────────────
    function refresh() {
        retryTimer.stop()
        countdownTimer.stop()
        retryCountdown = 0

        if (cfgApiKey.length === 0) {
            loading = false
            errorMessage = i18n("Please enter your API key in the settings.")
            return
        }
        loading = true
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
                    if (weatherData !== null) {
                        // Silent failure — existing data stays visible, normal timer retries
                        console.log("FancyKDEWeather: " + (err.code || "err") +
                                    (err.status ? " " + err.status : "") +
                                    " — keeping existing data, next retry in " +
                                    Math.round(cfgInterval / 60) + " min")
                        _retryCount = 0
                    } else {
                        // First load failed — show error and schedule aggressive retry
                        errorMessage = _translateError(err)
                        _scheduleRetry(err)
                    }
                } else {
                    weatherData   = data
                    errorMessage  = ""
                    _retryCount   = 0
                }
            }
        )
    }

    // ── Error code → localized message ──────────────────────────────────
    function _translateError(err) {
        if (!err) return i18n("Unknown error.")
        if (err.code === "ERR_NETWORK")
            return i18n("Unable to reach weather service.")
        if (err.code === "ERR_HTTP") {
            if (err.status === 400) return i18n("Invalid request — check your coordinates.")
            if (err.status === 401) return i18n("Invalid API key — please check your settings.")
            if (err.status === 429) return i18n("API rate limit reached.")
            return i18n("Weather service error (%1).", err.status)
        }
        if (err.code === "ERR_PARSE")
            return i18n("Could not parse weather data.")
        return i18n("Unknown error.")
    }

    // ── Retry scheduler ──────────────────────────────────────────────────
    function _scheduleRetry(err) {
        // Config errors require user action — no point retrying automatically
        if (err && err.code === "ERR_HTTP" && (err.status === 400 || err.status === 401))
            return
        var delays = [2, 2, 2, 2, 2, 5, 5, 5, 5, 5]  // seconds: 5×2 s then 5×5 s
        if (_retryCount < delays.length) {
            var secs = delays[_retryCount]
            _retryCount++
            retryCountdown = secs
            countdownTimer.restart()
            retryTimer.interval = secs * 1000
            retryTimer.restart()
        } else {
            // All retries exhausted — let updateTimer handle the next attempt
            _retryCount   = 0
            retryCountdown = 0
        }
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
    toolTipMainText: {
        if (!weatherData) return "Fancy KDE Weather"
        var c = weatherData.current
        return (c.city ? c.city + " — " : "") +
               (c.temperature !== null ? c.temperature + c.tempUnit : "—")
    }
    toolTipSubText: {
        if (weatherData) return weatherData.current.condition
        if (errorMessage) return errorMessage
        return i18n("Loading weather data…")
    }
    Plasmoid.icon: {
        if (weatherData) {
            var code = weatherData.current.iconCode
            return Qt.resolvedUrl("../icons/" + (code || "NA") + ".png")
        }
        return "weather-clear"
    }
}
