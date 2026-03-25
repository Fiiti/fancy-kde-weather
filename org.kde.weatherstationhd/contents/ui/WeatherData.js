// WeatherData.js
// Fetches weather from Visual Crossing API and parses into a normalized JS object.
//
// Icon mapping: VC string icons → numeric PNG codes (0.png–47.png)
// Derived from dev/weather_code_map.json (reverse mapping)
//
// Usage: WeatherData.fetchWeather(cfg, function(data, err) { ... })
// cfg  = { apiKey, latitude, longitude, units }
// data = { current, hourly[12], daily[7], astro }

.pragma library

var _pendingRequest     = null;
var _pendingCityRequest = null;
var _cityCache          = { key: "", name: "" }; // keyed by "lat,lon"

// Visual Crossing icon string → numeric PNG filename (reverse of weather_code_map.json)
var _vcIconToCode = {
    "clear-day":            "32",
    "clear-night":          "31",
    "cloudy":               "26",
    "fog":                  "20",
    "hail":                 "17",
    "partly-cloudy-day":    "30",
    "partly-cloudy-night":  "29",
    "rain":                 "12",
    "showers-day":          "39",
    "showers-night":        "45",
    "sleet":                "18",
    "snow":                 "16",
    "snow-showers-day":     "14",
    "snow-showers-night":   "46",
    "thunder":              "4",
    "thunder-rain":         "38",
    "thunder-showers-day":  "37",
    "thunder-showers-night":"47",
    "wind":                 "24"
};

// ── URL builder ──────────────────────────────────────────────────────────────

function buildUrl(cfg) {
    var unitGroup = cfg.units === "e" ? "us" : "metric";
    var elements = [
        "datetime", "tempmax", "tempmin", "temp", "feelslike",
        "humidity", "pressure", "winddir", "windspeed", "windgust",
        "visibility", "uvindex", "dew", "precipprob", "precip",
        "preciptype", "conditions", "icon",
        "sunrise", "sunset", "moonphase", "moonrise", "moonset", "description"
    ].join(",");

    return "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/"
        + encodeURIComponent(cfg.latitude + "," + cfg.longitude)
        + "?unitGroup=" + unitGroup
        + "&contentType=json"
        + "&include=days,hours,current,alerts"
        + "&elements=" + elements
        + "&key=" + cfg.apiKey;
}

// ── Fetch ────────────────────────────────────────────────────────────────────

// Fetches weather + city name in parallel. City name is cached per coordinate pair
// so Nominatim is only queried when coordinates actually change.
function fetchWeather(cfg, callback) {
    if (!cfg.apiKey || cfg.apiKey.length === 0) {
        callback(null, "Kein API-Schlüssel konfiguriert. Bitte in den Einstellungen eintragen.");
        return;
    }

    // Abort any in-flight requests from a previous call
    if (_pendingRequest)     { _pendingRequest.abort();     _pendingRequest     = null; }
    if (_pendingCityRequest) { _pendingCityRequest.abort(); _pendingCityRequest = null; }

    // Each fetchWeather call owns its own state — closures keep them separate
    var state = { weatherData: null, weatherErr: null, city: null,
                  weatherDone: false, cityDone: false, cancelled: false };

    function _tryFinish() {
        if (state.cancelled || !state.weatherDone || !state.cityDone) return;
        if (state.weatherErr) { callback(null, state.weatherErr); return; }
        if (state.city) state.weatherData.current.city = state.city;
        callback(state.weatherData, null);
    }

    // ── Weather XHR ──────────────────────────────────────────────────────────
    var wxhr = new XMLHttpRequest();
    _pendingRequest = wxhr;

    wxhr.onreadystatechange = function() {
        if (wxhr.readyState !== XMLHttpRequest.DONE) return;
        _pendingRequest = null;

        if (wxhr.status === 0) { state.cancelled = true; return; } // Aborted

        if (wxhr.status !== 200) {
            state.weatherErr  = "HTTP-Fehler " + wxhr.status + ": " + wxhr.statusText;
            state.weatherDone = true;
            _tryFinish();
            return;
        }

        try {
            state.weatherData = _parseResponse(JSON.parse(wxhr.responseText), cfg.units);
        } catch (e) {
            state.weatherErr = "Fehler beim Verarbeiten der API-Antwort: " + e.message;
        }
        state.weatherDone = true;
        _tryFinish();
    };

    wxhr.open("GET", buildUrl(cfg));
    wxhr.send();

    // ── Nominatim reverse geocoding (cached per coordinate pair) ─────────────
    var cacheKey = cfg.latitude + "," + cfg.longitude;

    if (_cityCache.key === cacheKey) {
        // Cache hit — no network request needed
        state.city     = _cityCache.name;
        state.cityDone = true;
        _tryFinish();
    } else {
        var cxhr = new XMLHttpRequest();
        _pendingCityRequest = cxhr;

        cxhr.onreadystatechange = function() {
            if (cxhr.readyState !== XMLHttpRequest.DONE) return;
            _pendingCityRequest = null;

            if (cxhr.status === 200) {
                try {
                    var addr = (JSON.parse(cxhr.responseText).address) || {};
                    var name = addr.town || addr.city || addr.village
                             || addr.suburb || addr.municipality || "";
                    _cityCache        = { key: cacheKey, name: name };
                    state.city        = name;
                } catch (e) {}
            }
            state.cityDone = true;
            _tryFinish();
        };

        cxhr.open("GET",
            "https://nominatim.openstreetmap.org/reverse"
            + "?lat=" + cfg.latitude + "&lon=" + cfg.longitude + "&format=json");
        cxhr.setRequestHeader("User-Agent", "WeatherStationHD-KDE-Plasmoid/1.0");
        cxhr.send();
    }
}

// ── Helper functions ─────────────────────────────────────────────────────────

function _iconCode(vcIcon) {
    return _vcIconToCode[vcIcon] || "NA";
}

// Wind degrees (0–360) → 16-point cardinal string
function _degreesToCardinal(deg) {
    if (deg === null || deg === undefined) return "";
    var dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"];
    return dirs[Math.round(deg / 22.5) % 16];
}

// UV index → German description
function _uvDescription(idx) {
    if (idx === null || idx === undefined) return "";
    if (idx <= 2)  return "Niedrig";
    if (idx <= 5)  return "Mittel";
    if (idx <= 7)  return "Hoch";
    if (idx <= 10) return "Sehr hoch";
    return "Extrem";
}

// Moon phase float (0.0–1.0) → phase code for moon PNG icons
// 0.0 = New Moon, 0.25 = First Quarter, 0.5 = Full Moon, 0.75 = Last Quarter
function _moonPhaseCode(phase) {
    if (phase < 0.063) return "N";    // New Moon
    if (phase < 0.188) return "WXC";  // Waxing Crescent
    if (phase < 0.313) return "FQ";   // First Quarter
    if (phase < 0.438) return "WXG";  // Waxing Gibbous
    if (phase < 0.563) return "F";    // Full Moon
    if (phase < 0.688) return "WNG";  // Waning Gibbous
    if (phase < 0.813) return "LQ";   // Last Quarter
    if (phase < 0.938) return "WNC";  // Waning Crescent
    return "N";
}

// "2026-03-25" → German short weekday name ("Mo", "Di", …)
function _dayName(dateStr) {
    if (!dateStr) return "";
    var names = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"];
    // Use T12:00:00 to avoid UTC-midnight date-shift issues in European timezone
    var d = new Date(dateStr + "T12:00:00");
    return names[d.getDay()];
}

// Extract 12 hourly entries starting from the current hour,
// spanning into tomorrow's hours if needed.
function _extractHourly(days) {
    var currentHour   = new Date().getHours();
    var todayHours    = (days[0] && days[0].hours) ? days[0].hours : [];
    var tomorrowHours = (days[1] && days[1].hours) ? days[1].hours : [];
    var result = [];
    for (var i = currentHour; i < todayHours.length && result.length < 12; i++)
        result.push(todayHours[i]);
    for (var j = 0; j < tomorrowHours.length && result.length < 12; j++)
        result.push(tomorrowHours[j]);
    return result;
}

// ── Response parser ──────────────────────────────────────────────────────────

function _parseResponse(raw, units) {
    var cur  = raw.currentConditions || {};
    var days = raw.days || [];
    var day0 = days[0] || {};

    var tempUnit  = units === "e" ? "°F"   : "°C";
    var speedUnit = units === "e" ? "mph"  : "km/h";
    var pressUnit = units === "e" ? "inHg" : "hPa";
    var visUnit   = units === "e" ? "mi"   : "km";

    // --- CURRENT CONDITIONS ---
    var current = {
        city:         raw.resolvedAddress || "",
        iconCode:     _iconCode(cur.icon),
        temperature:  cur.temp      !== undefined ? Math.round(cur.temp)      : null,
        feelsLike:    cur.feelslike !== undefined ? Math.round(cur.feelslike) : null,
        condition:    cur.conditions || "",
        humidity:     cur.humidity  !== undefined ? Math.round(cur.humidity)  : null,
        pressure:     cur.pressure  !== undefined ? cur.pressure              : null,
        windDir:      _degreesToCardinal(cur.winddir),
        windSpeed:    cur.windspeed !== undefined ? Math.round(cur.windspeed) : null,
        windGust:     (cur.windgust !== null && cur.windgust !== undefined && cur.windgust > 0)
                      ? Math.round(cur.windgust) : null,
        visibility:   cur.visibility !== undefined ? cur.visibility           : null,
        uvIndex:      cur.uvindex   !== undefined ? cur.uvindex               : null,
        uvDescription: _uvDescription(cur.uvindex),
        dewPoint:     cur.dew       !== undefined ? Math.round(cur.dew)      : null,
        tempUnit:     tempUnit,
        speedUnit:    speedUnit,
        pressUnit:    pressUnit,
        visUnit:      visUnit
    };

    // --- HOURLY FORECAST (12h from current hour) ---
    var hourly = _extractHourly(days).map(function(h) {
        return {
            time:         h.datetime   || "",
            iconCode:     _iconCode(h.icon),
            temperature:  h.temp       !== undefined ? Math.round(h.temp)  : null,
            precipChance: h.precipprob !== undefined ? h.precipprob        : null,
            condition:    h.conditions || ""
        };
    });

    // --- DAILY FORECAST (7 days) ---
    var daily = [];
    for (var d = 0; d < 7 && d < days.length; d++) {
        var day = days[d];
        daily.push({
            dayName:      _dayName(day.datetime || ""),
            iconCode:     _iconCode(day.icon),
            tempMax:      day.tempmax   !== undefined ? Math.round(day.tempmax)  : null,
            tempMin:      day.tempmin   !== undefined ? Math.round(day.tempmin)  : null,
            precipChance: day.precipprob !== undefined ? day.precipprob          : null
        });
    }

    // --- ASTRONOMICAL DATA (from day0 + currentConditions) ---
    var moonPhase = day0.moonphase !== undefined ? day0.moonphase : (cur.moonphase || 0);
    var astro = {
        moonPhaseCode: _moonPhaseCode(moonPhase),
        moonPhase:     String(moonPhase),
        sunrise:       cur.sunrise  || day0.sunrise  || "",
        sunset:        cur.sunset   || day0.sunset   || "",
        moonrise:      day0.moonrise || "",
        moonset:       day0.moonset  || ""
    };

    return { current: current, hourly: hourly, daily: daily, astro: astro };
}
