import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: fullRoot

    // Wide horizontal banner, like the original Rainmeter widget
    Layout.preferredWidth:  Kirigami.Units.gridUnit * 58
    Layout.preferredHeight: Kirigami.Units.gridUnit * 20
    Layout.minimumWidth:    Kirigami.Units.gridUnit * 40
    Layout.minimumHeight:   Kirigami.Units.gridUnit * 16

    // ── Background ──────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius
        color: {
            var hex = Plasmoid.configuration.bgColor || "#1a1a2e"
            var c   = Qt.color(hex)
            var a   = Plasmoid.configuration.bgAlpha
            return Qt.rgba(c.r, c.g, c.b, (a !== undefined) ? a : 0.85)
        }
    }

    // ── Right-click → settings ──────────────────────────────────────────
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: plasmoid.internalAction("configure").trigger()
    }

    // ── Clock (updates every second) ────────────────────────────────────
    Timer {
        interval: 1000
        running:  root.cfgShowClock
        repeat:   true
        triggeredOnStart: true
        onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH : mm")
    }

    // ── Loading / error overlay ─────────────────────────────────────────
    Loader {
        anchors.fill:    parent
        anchors.margins: Kirigami.Units.gridUnit
        active:  root.loading || (root.errorMessage.length > 0 && !root.weatherData)
        z: 10

        sourceComponent: Component {
            Item {
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        visible: root.loading
                        source:  "view-refresh"
                        Layout.alignment:       Qt.AlignHCenter
                        Layout.preferredWidth:  Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: Kirigami.Units.iconSizes.large
                        opacity: 0.6

                        RotationAnimator on rotation {
                            running:  root.loading
                            from: 0; to: 360
                            duration: 1500
                            loops:    Animation.Infinite
                        }
                    }

                    Text {
                        Layout.alignment:    Qt.AlignHCenter
                        Layout.maximumWidth: fullRoot.width * 0.8
                        text:      root.loading
                                   ? i18n("Loading weather data…")
                                   : root.errorMessage
                        color:     root.loading ? "white" : "#FF6B6B"
                        wrapMode:  Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Kirigami.Units.gridUnit * 0.85
                    }
                }
            }
        }
    }

    // ── Main content ────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill:    parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: 0
        visible: root.weatherData !== null

        // ── Top row: Current conditions (left) + Info+Daily (right) ────
        RowLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            spacing: 0

            // Left: current weather — fixed width, does not shrink with widget
            CurrentWeather {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 25
                Layout.minimumWidth:   Kirigami.Units.gridUnit * 25
                Layout.maximumWidth:   Kirigami.Units.gridUnit * 25
                Layout.fillHeight:     true
                Layout.leftMargin:     Kirigami.Units.smallSpacing
                weatherData:           root.weatherData
            }

            // Vertical separator
            Rectangle {
                width:               1
                Layout.fillHeight:   true
                Layout.topMargin:    Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                color:               Qt.rgba(1, 1, 1, 0.2)
            }

            // Right: info header + 7-day forecast
            ColumnLayout {
                Layout.fillWidth:    true
                Layout.fillHeight:   true
                Layout.leftMargin:   Kirigami.Units.gridUnit * 0.75
                Layout.rightMargin:  Kirigami.Units.smallSpacing
                Layout.topMargin:    Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                spacing:             Kirigami.Units.smallSpacing * 0.5

                // Info row: city | sunrise | sunset | date | moon | clock
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    Text {
                        text:           new Date().toLocaleDateString(Qt.locale(root.cfgLang), "dddd, d MMMM yyyy")
                        color:          Qt.rgba(1, 1, 1, 0.85)
                        font.pixelSize: Kirigami.Units.gridUnit * 0.82
                        font.bold:      true
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 3
                        Kirigami.Icon {
                            source: "weather-clear"
                            Layout.preferredWidth:  Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        }
                        Text {
                            text:           root.weatherData
                                            ? _formatTime(root.weatherData.astro.sunrise)
                                            : "—"
                            color:          "white"
                            font.pixelSize: Kirigami.Units.gridUnit * 0.78
                        }
                    }

                    RowLayout {
                        spacing: 3
                        Kirigami.Icon {
                            source: "weather-clear-night"
                            Layout.preferredWidth:  Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        }
                        Text {
                            text:           root.weatherData
                                            ? _formatTime(root.weatherData.astro.sunset)
                                            : "—"
                            color:          "white"
                            font.pixelSize: Kirigami.Units.gridUnit * 0.78
                        }
                    }

                    // Moon phase image + moonrise/moonset with day prefix
                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Image {
                            source: root.weatherData
                                    ? root.moonIconPath(root.weatherData.astro.moonPhaseCode)
                                    : ""
                            Layout.preferredWidth:  Kirigami.Units.gridUnit * 1.8
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                            fillMode: Image.PreserveAspectFit
                            smooth:   true
                            opacity:  0.9
                        }

                        ColumnLayout {
                            spacing: 1
                            Text {
                                text:           root.weatherData
                                                ? ("↑ " + _formatDayTime(root.weatherData.astro.moonriseDate,
                                                                         root.weatherData.astro.moonrise))
                                                : ""
                                color:          Qt.rgba(1, 1, 1, 0.75)
                                font.pixelSize: Kirigami.Units.gridUnit * 0.65
                            }
                            Text {
                                text:           root.weatherData
                                                ? ("↓ " + _formatDayTime(root.weatherData.astro.moonsetDate,
                                                                         root.weatherData.astro.moonset))
                                                : ""
                                color:          Qt.rgba(1, 1, 1, 0.75)
                                font.pixelSize: Kirigami.Units.gridUnit * 0.65
                            }
                        }
                    }

                    Text {
                        id:             clockText
                        visible:        root.cfgShowClock
                        color:          "white"
                        font.pixelSize: Kirigami.Units.gridUnit * 1.1
                        font.bold:      true
                    }
                }

                // Separator under info row
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color:  Qt.rgba(1, 1, 1, 0.15)
                }

                // 7-day forecast — horizontal columns
                DailyForecast {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    dailyData: root.weatherData ? root.weatherData.daily : []
                    tempUnit:  root.weatherData ? root.weatherData.current.tempUnit : "°C"
                }
            }
        }

        // Horizontal separator
        Rectangle {
            Layout.fillWidth:   true
            Layout.leftMargin:  Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.topMargin:   -Kirigami.Units.gridUnit * 0.5
            height: 1
            color:  Qt.rgba(1, 1, 1, 0.15)
        }

        // ── Bottom: 12-hour forecast ────────────────────────────────────
        HourlyForecast {
            Layout.fillWidth:       true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5.5
            Layout.leftMargin:      Kirigami.Units.smallSpacing
            Layout.rightMargin:     Kirigami.Units.smallSpacing
            Layout.bottomMargin:    Kirigami.Units.smallSpacing
            hourlyData: root.weatherData ? root.weatherData.hourly : []
            tempUnit:   root.weatherData ? root.weatherData.current.tempUnit : "°C"
        }
    }

    // VC time format: "HH:MM:SS" → "HH:MM"
    function _formatTime(isoStr) {
        if (!isoStr || isoStr.length < 5) return ""
        return isoStr.substring(0, 5)
    }

    // "2026-03-25" + "HH:MM:SS" → "Mo, 08:50"  (or "05., 08:50" as fallback)
    function _formatDayTime(dateStr, timeStr) {
        if (!timeStr || timeStr.length < 5) return ""
        var time = timeStr.substring(0, 5)
        if (!dateStr) return time
        var d = new Date(dateStr + "T12:00:00")
        var dayPart = ""
        try {
            dayPart = d.toLocaleDateString(Qt.locale(root.cfgLang), "ddd")
            dayPart = dayPart.replace(/\.$/, "")  // "Mo." → "Mo"
        } catch(e) {
            dayPart = ("0" + d.getDate()).slice(-2) + "."
        }
        return dayPart + ", " + time
    }
}
