// WeatherData.js
// Fetches weather from Visual Crossing API and parses into a normalized JS object.
//
// Usage: WeatherData.fetchWeather(cfg, function(data, err) { ... })
// cfg  = { apiKey, latitude, longitude, units, language }
// data = { current, hourly[12], daily[7], astro }

.pragma library

var _pendingRequest     = null;
var _pendingCityRequest = null;
var _cityCache          = { key: "", name: "" };
var _requestId          = 0;

// ── Icon mapping: VC string → numeric PNG filename ────────────────────────────

var _vcIconToCode = {
    "clear-day":             "32",
    "clear-night":           "31",
    "cloudy":                "26",
    "fog":                   "20",
    "hail":                  "17",
    "partly-cloudy-day":     "30",
    "partly-cloudy-night":   "29",
    "rain":                  "12",
    "showers-day":           "39",
    "showers-night":         "45",
    "sleet":                 "18",
    "snow":                  "16",
    "snow-showers-day":      "14",
    "snow-showers-night":    "46",
    "thunder":               "4",
    "thunder-rain":          "38",
    "thunder-showers-day":   "37",
    "thunder-showers-night": "47",
    "wind":                  "24"
};

// ── Condition translations: VC icon string → localized text ──────────────────
// Keyed by VC icon name, then language code.
// Fallback chain: requested language → en-US → raw icon string.

var _conditionText = {
    "clear-day": {
        "de-DE": "Klar",               "en-US": "Clear",
        "fr-FR": "Dégagé",             "es-ES": "Despejado",
        "it-IT": "Sereno",             "nl-NL": "Helder",
        "pl-PL": "Bezchmurnie",        "pt-BR": "Céu limpo",
        "ru-RU": "Ясно",               "zh-CN": "晴天"
    },
    "clear-night": {
        "de-DE": "Klar",               "en-US": "Clear",
        "fr-FR": "Dégagé",             "es-ES": "Despejado",
        "it-IT": "Sereno",             "nl-NL": "Helder",
        "pl-PL": "Bezchmurnie",        "pt-BR": "Céu limpo",
        "ru-RU": "Ясно",               "zh-CN": "晴夜"
    },
    "cloudy": {
        "de-DE": "Bewölkt",            "en-US": "Cloudy",
        "fr-FR": "Nuageux",            "es-ES": "Nublado",
        "it-IT": "Nuvoloso",           "nl-NL": "Bewolkt",
        "pl-PL": "Pochmurno",          "pt-BR": "Nublado",
        "ru-RU": "Облачно",            "zh-CN": "阴天"
    },
    "fog": {
        "de-DE": "Nebel",              "en-US": "Fog",
        "fr-FR": "Brouillard",         "es-ES": "Niebla",
        "it-IT": "Nebbia",             "nl-NL": "Mist",
        "pl-PL": "Mgła",               "pt-BR": "Neblina",
        "ru-RU": "Туман",              "zh-CN": "雾"
    },
    "hail": {
        "de-DE": "Hagel",              "en-US": "Hail",
        "fr-FR": "Grêle",              "es-ES": "Granizo",
        "it-IT": "Grandine",           "nl-NL": "Hagel",
        "pl-PL": "Grad",               "pt-BR": "Granizo",
        "ru-RU": "Град",               "zh-CN": "冰雹"
    },
    "partly-cloudy-day": {
        "de-DE": "Teils bewölkt",      "en-US": "Partly cloudy",
        "fr-FR": "Partiellement nuageux", "es-ES": "Parcialmente nublado",
        "it-IT": "Parzialmente nuvoloso", "nl-NL": "Gedeeltelijk bewolkt",
        "pl-PL": "Częściowe zachmurzenie", "pt-BR": "Parcialmente nublado",
        "ru-RU": "Переменная облачность", "zh-CN": "局部多云"
    },
    "partly-cloudy-night": {
        "de-DE": "Teils bewölkt",      "en-US": "Partly cloudy",
        "fr-FR": "Partiellement nuageux", "es-ES": "Parcialmente nublado",
        "it-IT": "Parzialmente nuvoloso", "nl-NL": "Gedeeltelijk bewolkt",
        "pl-PL": "Częściowe zachmurzenie", "pt-BR": "Parcialmente nublado",
        "ru-RU": "Переменная облачность", "zh-CN": "局部多云"
    },
    "rain": {
        "de-DE": "Regen",              "en-US": "Rain",
        "fr-FR": "Pluie",              "es-ES": "Lluvia",
        "it-IT": "Pioggia",            "nl-NL": "Regen",
        "pl-PL": "Deszcz",             "pt-BR": "Chuva",
        "ru-RU": "Дождь",              "zh-CN": "雨"
    },
    "showers-day": {
        "de-DE": "Schauer",            "en-US": "Showers",
        "fr-FR": "Averses",            "es-ES": "Chubascos",
        "it-IT": "Rovesci",            "nl-NL": "Buien",
        "pl-PL": "Przelotne opady",    "pt-BR": "Pancadas de chuva",
        "ru-RU": "Ливень",             "zh-CN": "阵雨"
    },
    "showers-night": {
        "de-DE": "Schauer",            "en-US": "Showers",
        "fr-FR": "Averses",            "es-ES": "Chubascos",
        "it-IT": "Rovesci",            "nl-NL": "Buien",
        "pl-PL": "Przelotne opady",    "pt-BR": "Pancadas de chuva",
        "ru-RU": "Ливень",             "zh-CN": "夜间阵雨"
    },
    "sleet": {
        "de-DE": "Schneeregen",        "en-US": "Sleet",
        "fr-FR": "Grésil",             "es-ES": "Aguanieve",
        "it-IT": "Nevischio",          "nl-NL": "IJzel",
        "pl-PL": "Deszcz ze śniegiem", "pt-BR": "Chuva com neve",
        "ru-RU": "Мокрый снег",        "zh-CN": "雨夹雪"
    },
    "snow": {
        "de-DE": "Schnee",             "en-US": "Snow",
        "fr-FR": "Neige",              "es-ES": "Nieve",
        "it-IT": "Neve",               "nl-NL": "Sneeuw",
        "pl-PL": "Śnieg",              "pt-BR": "Neve",
        "ru-RU": "Снег",               "zh-CN": "雪"
    },
    "snow-showers-day": {
        "de-DE": "Schneeschauer",      "en-US": "Snow showers",
        "fr-FR": "Averses de neige",   "es-ES": "Chubascos de nieve",
        "it-IT": "Rovesci di neve",    "nl-NL": "Sneeuwbuien",
        "pl-PL": "Przelotne opady śniegu", "pt-BR": "Pancadas de neve",
        "ru-RU": "Снежный ливень",     "zh-CN": "阵雪"
    },
    "snow-showers-night": {
        "de-DE": "Schneeschauer",      "en-US": "Snow showers",
        "fr-FR": "Averses de neige",   "es-ES": "Chubascos de nieve",
        "it-IT": "Rovesci di neve",    "nl-NL": "Sneeuwbuien",
        "pl-PL": "Przelotne opady śniegu", "pt-BR": "Pancadas de neve",
        "ru-RU": "Снежный ливень",     "zh-CN": "夜间阵雪"
    },
    "thunder": {
        "de-DE": "Gewitter",           "en-US": "Thunder",
        "fr-FR": "Orage",              "es-ES": "Tormenta",
        "it-IT": "Temporale",          "nl-NL": "Onweer",
        "pl-PL": "Burza",              "pt-BR": "Trovoada",
        "ru-RU": "Гроза",              "zh-CN": "雷暴"
    },
    "thunder-rain": {
        "de-DE": "Gewitter mit Regen", "en-US": "Thunderstorm",
        "fr-FR": "Orage avec pluie",   "es-ES": "Tormenta con lluvia",
        "it-IT": "Temporale con pioggia", "nl-NL": "Onweer met regen",
        "pl-PL": "Burza z deszczem",   "pt-BR": "Tempestade",
        "ru-RU": "Гроза с дождём",     "zh-CN": "雷雨"
    },
    "thunder-showers-day": {
        "de-DE": "Gewitterschauer",    "en-US": "Thunder showers",
        "fr-FR": "Averses orageuses",  "es-ES": "Chubascos tormentosos",
        "it-IT": "Rovesci temporaleschi", "nl-NL": "Onweersbuien",
        "pl-PL": "Przelotne burze",    "pt-BR": "Pancadas com trovoada",
        "ru-RU": "Грозовые ливни",     "zh-CN": "雷阵雨"
    },
    "thunder-showers-night": {
        "de-DE": "Gewitterschauer",    "en-US": "Thunder showers",
        "fr-FR": "Averses orageuses",  "es-ES": "Chubascos tormentosos",
        "it-IT": "Rovesci temporaleschi", "nl-NL": "Onweersbuien",
        "pl-PL": "Przelotne burze",    "pt-BR": "Pancadas com trovoada",
        "ru-RU": "Грозовые ливni",     "zh-CN": "夜间雷阵雨"
    },
    "wind": {
        "de-DE": "Windig",             "en-US": "Windy",
        "fr-FR": "Venteux",            "es-ES": "Ventoso",
        "it-IT": "Ventoso",            "nl-NL": "Winderig",
        "pl-PL": "Wietrznie",          "pt-BR": "Ventoso",
        "ru-RU": "Ветрено",            "zh-CN": "有风"
    }
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

function fetchWeather(cfg, callback) {
    if (!cfg.apiKey || cfg.apiKey.length === 0) {
        callback(null, { code: "ERR_NO_API_KEY" });
        return;
    }

    if (_pendingRequest)     { _pendingRequest.abort();     _pendingRequest     = null; }
    if (_pendingCityRequest) { _pendingCityRequest.abort(); _pendingCityRequest = null; }

    var thisId = ++_requestId;
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

        // Superseded by a newer fetchWeather call (intentional abort) → ignore silently
        if (thisId !== _requestId) { state.cancelled = true; return; }

        if (wxhr.status === 0) {
            state.weatherErr  = { code: "ERR_NETWORK" };
            state.weatherDone = true;
            _tryFinish();
            return;
        }

        if (wxhr.status !== 200) {
            state.weatherErr  = { code: "ERR_HTTP", status: wxhr.status };
            state.weatherDone = true;
            _tryFinish();
            return;
        }

        try {
            state.weatherData = _parseResponse(JSON.parse(wxhr.responseText), cfg.units, cfg.language);
        } catch (e) {
            state.weatherErr = { code: "ERR_PARSE" };
        }
        state.weatherDone = true;
        _tryFinish();
    };

    wxhr.open("GET", buildUrl(cfg));
    wxhr.send();

    // ── Nominatim reverse geocoding (cached per coordinate pair) ─────────────
    var cacheKey = cfg.latitude + "," + cfg.longitude;

    if (_cityCache.key === cacheKey) {
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
                    var name = addr.city        || addr.town         || addr.village
                             || addr.hamlet     || addr.suburb       || addr.city_district
                             || addr.district   || addr.municipality || addr.county || "";
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
        cxhr.setRequestHeader("User-Agent", "FancyKDEWeather/1.0 (github.com/Fiiti/fancy-kde-weather)");
        cxhr.send();
    }
}

// ── Standalone city lookup (used for independent retry without re-fetching weather) ──

function fetchCity(cfg, callback) {
    var cacheKey = cfg.latitude + "," + cfg.longitude;
    if (_cityCache.key === cacheKey && _cityCache.name) {
        callback(_cityCache.name);
        return;
    }
    if (_pendingCityRequest) { _pendingCityRequest.abort(); _pendingCityRequest = null; }
    var cxhr = new XMLHttpRequest();
    _pendingCityRequest = cxhr;
    cxhr.onreadystatechange = function() {
        if (cxhr.readyState !== XMLHttpRequest.DONE) return;
        _pendingCityRequest = null;
        if (cxhr.status === 200) {
            try {
                var addr = JSON.parse(cxhr.responseText).address || {};
                var name = addr.city        || addr.town         || addr.village
                         || addr.hamlet     || addr.suburb       || addr.city_district
                         || addr.district   || addr.municipality || addr.county || "";
                _cityCache = { key: cacheKey, name: name };
                callback(name);
                return;
            } catch(e) {}
        }
        callback("");
    };
    cxhr.open("GET", "https://nominatim.openstreetmap.org/reverse?lat=" + cfg.latitude + "&lon=" + cfg.longitude + "&format=json");
    cxhr.setRequestHeader("User-Agent", "FancyKDEWeather/1.0 (github.com/Fiiti/fancy-kde-weather)");
    cxhr.send();
}

// ── Helper functions ─────────────────────────────────────────────────────────

function _iconCode(vcIcon) {
    return _vcIconToCode[vcIcon] || "NA";
}

// VC icon string + language → localized condition text
function _translateCondition(vcIcon, language) {
    var map = _conditionText[vcIcon];
    if (!map) return vcIcon;
    return map[language] || map["en-US"] || vcIcon;
}

// Wind degrees (0–360) → 16-point cardinal string
function _degreesToCardinal(deg) {
    if (deg === null || deg === undefined) return "";
    var dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"];
    return dirs[Math.round(deg / 22.5) % 16];
}

// UV index level → localized description (WHO scale)
var _uvLevels = [
    { max:  2, "de-DE": "Niedrig",       "en-US": "Low",       "fr-FR": "Faible",       "es-ES": "Bajo",        "it-IT": "Basso",         "nl-NL": "Laag",         "pl-PL": "Niski",           "pt-BR": "Baixo",      "ru-RU": "Низкий",           "zh-CN": "低"   },
    { max:  5, "de-DE": "Mittel",        "en-US": "Moderate",  "fr-FR": "Modéré",       "es-ES": "Moderado",    "it-IT": "Moderato",      "nl-NL": "Matig",        "pl-PL": "Umiarkowany",     "pt-BR": "Moderado",   "ru-RU": "Умеренный",        "zh-CN": "中等" },
    { max:  7, "de-DE": "Hoch",          "en-US": "High",      "fr-FR": "Élevé",        "es-ES": "Alto",        "it-IT": "Alto",          "nl-NL": "Hoog",         "pl-PL": "Wysoki",          "pt-BR": "Alto",       "ru-RU": "Высокий",          "zh-CN": "高"   },
    { max: 10, "de-DE": "Sehr hoch",     "en-US": "Very high", "fr-FR": "Très élevé",   "es-ES": "Muy alto",    "it-IT": "Molto alto",    "nl-NL": "Zeer hoog",    "pl-PL": "Bardzo wysoki",   "pt-BR": "Muito alto", "ru-RU": "Очень высокий",    "zh-CN": "极高" },
    { max: 99, "de-DE": "Extrem",        "en-US": "Extreme",   "fr-FR": "Extrême",      "es-ES": "Extremo",     "it-IT": "Estremo",       "nl-NL": "Extreem",      "pl-PL": "Ekstremalny",     "pt-BR": "Extremo",    "ru-RU": "Экстремальный",    "zh-CN": "极端" }
];

function _uvDescription(idx, language) {
    if (idx === null || idx === undefined) return "";
    var lang = language || "en-US";
    for (var i = 0; i < _uvLevels.length; i++) {
        if (idx <= _uvLevels[i].max)
            return _uvLevels[i][lang] || _uvLevels[i]["en-US"];
    }
    return "";
}

// Moon phase float (0.0–1.0) → phase code for moon PNG icons
function _moonPhaseCode(phase) {
    if (phase < 0.063) return "N";
    if (phase < 0.188) return "WXC";
    if (phase < 0.313) return "FQ";
    if (phase < 0.438) return "WXG";
    if (phase < 0.563) return "F";
    if (phase < 0.688) return "WNG";
    if (phase < 0.813) return "LQ";
    if (phase < 0.938) return "WNC";
    return "N";
}

// "2026-03-25" + language → localized short weekday name
// Uses Intl API (Qt 6 / V4 engine with ICU). Hardcoded fallback if unavailable.
function _dayName(dateStr, language) {
    if (!dateStr) return "";
    var d = new Date(dateStr + "T12:00:00");
    try {
        var name = d.toLocaleDateString(language || "en-US", { weekday: "short" });
        return name.replace(/\.$/, ""); // remove trailing period (e.g. "Mo." → "Mo")
    } catch(e) {
        var fallback = {
            "de-DE": ["So","Mo","Di","Mi","Do","Fr","Sa"],
            "en-US": ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],
            "fr-FR": ["Dim","Lun","Mar","Mer","Jeu","Ven","Sam"],
            "es-ES": ["Dom","Lun","Mar","Mié","Jue","Vie","Sáb"],
            "it-IT": ["Dom","Lun","Mar","Mer","Gio","Ven","Sab"],
            "nl-NL": ["Zo","Ma","Di","Wo","Do","Vr","Za"],
            "pl-PL": ["Nie","Pon","Wt","Śr","Czw","Pt","Sob"],
            "pt-BR": ["Dom","Seg","Ter","Qua","Qui","Sex","Sáb"],
            "ru-RU": ["Вс","Пн","Вт","Ср","Чт","Пт","Сб"],
            "zh-CN": ["日","一","二","三","四","五","六"]
        };
        var names = fallback[language] || fallback["en-US"];
        return names[d.getDay()];
    }
}

// Extract 12 hourly entries starting from the current hour
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

function _parseResponse(raw, units, language) {
    var lang = language || "en-US";
    var cur  = raw.currentConditions || {};
    var days = raw.days || [];
    var day0 = days[0] || {};

    var tempUnit  = units === "e" ? "°F"   : "°C";
    var speedUnit = units === "e" ? "mph"  : "km/h";
    var pressUnit = units === "e" ? "inHg" : "hPa";
    var visUnit   = units === "e" ? "mi"   : "km";

    // --- CURRENT CONDITIONS ---
    var current = {
        city:          (raw.resolvedAddress || "").split(",")[0].trim() || "",
        iconCode:      _iconCode(cur.icon),
        temperature:   cur.temp      !== undefined ? Math.round(cur.temp)      : null,
        feelsLike:     cur.feelslike !== undefined ? Math.round(cur.feelslike) : null,
        condition:     _translateCondition(cur.icon, lang),
        humidity:      cur.humidity  !== undefined ? Math.round(cur.humidity)  : null,
        pressure:      cur.pressure  !== undefined ? cur.pressure              : null,
        windDir:       _degreesToCardinal(cur.winddir),
        windSpeed:     cur.windspeed !== undefined ? Math.round(cur.windspeed) : null,
        windGust:      (cur.windgust !== null && cur.windgust !== undefined && cur.windgust > 0)
                       ? Math.round(cur.windgust) : null,
        visibility:    cur.visibility !== undefined ? cur.visibility           : null,
        uvIndex:       cur.uvindex   !== undefined ? cur.uvindex               : null,
        uvDescription: _uvDescription(cur.uvindex, lang),
        dewPoint:      cur.dew       !== undefined ? Math.round(cur.dew)       : null,
        tempUnit:      tempUnit,
        speedUnit:     speedUnit,
        pressUnit:     pressUnit,
        visUnit:       visUnit
    };

    // --- HOURLY FORECAST (12h from current hour) ---
    var hourly = _extractHourly(days).map(function(h) {
        return {
            time:         h.datetime   || "",
            iconCode:     _iconCode(h.icon),
            temperature:  h.temp       !== undefined ? Math.round(h.temp) : null,
            precipChance: h.precipprob !== undefined ? h.precipprob       : null,
            condition:    _translateCondition(h.icon, lang)
        };
    });

    // --- DAILY FORECAST (7 days) ---
    var daily = [];
    for (var d = 0; d < 7 && d < days.length; d++) {
        var day = days[d];
        daily.push({
            dayName:      _dayName(day.datetime || "", lang),
            iconCode:     _iconCode(day.icon),
            tempMax:      day.tempmax    !== undefined ? Math.round(day.tempmax)  : null,
            tempMin:      day.tempmin    !== undefined ? Math.round(day.tempmin)  : null,
            precipChance: day.precipprob !== undefined ? day.precipprob           : null
        });
    }

    // --- ASTRONOMICAL DATA ---
    var moonPhase = day0.moonphase !== undefined ? day0.moonphase : (cur.moonphase || 0);
    // Moonset can be the following day if its time is earlier than moonrise (moon sets after midnight)
    var moonriseDate = day0.datetime || "";
    var moonsetDate  = day0.datetime || "";
    if (day0.moonset && day0.moonrise && day0.moonset < day0.moonrise)
        moonsetDate = (days[1] && days[1].datetime) || day0.datetime || "";
    var astro = {
        moonPhaseCode: _moonPhaseCode(moonPhase),
        moonPhase:     String(moonPhase),
        sunrise:       cur.sunrise   || day0.sunrise  || "",
        sunset:        cur.sunset    || day0.sunset   || "",
        moonrise:      day0.moonrise || "",
        moonset:       day0.moonset  || "",
        moonriseDate:  moonriseDate,
        moonsetDate:   moonsetDate
    };

    return { current: current, hourly: hourly, daily: daily, astro: astro };
}
