import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: currentRoot

    property var weatherData: null
    readonly property var cur: weatherData ? weatherData.current : null

    implicitHeight: mainLayout.implicitHeight

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        spacing:      Kirigami.Units.gridUnit

        // ── Left: Icon + Temperature + Condition ─────────────────────────
        ColumnLayout {
            Layout.alignment:  Qt.AlignTop
            spacing:           Kirigami.Units.smallSpacing / 2

            Image {
                source:                 cur ? root.weatherIconPath(cur.iconCode) : ""
                Layout.preferredWidth:  Kirigami.Units.gridUnit * 7.0
                Layout.preferredHeight: Kirigami.Units.gridUnit * 7.0
                fillMode:               Image.PreserveAspectFit
                smooth:                 true
            }

            Text {
                text: {
                    if (!cur) return "—"
                    return cur.temperature !== null
                           ? (cur.temperature + cur.tempUnit)
                           : "—"
                }
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 2.0
                font.bold:      true
            }

            Text {
                visible:        cur && cur.feelsLike !== null
                text:           cur ? qsTr("Gefühlt %1%2")
                                      .arg(cur.feelsLike)
                                      .arg(cur.tempUnit)
                                    : ""
                color:          Qt.rgba(1, 1, 1, 0.75)
                font.pixelSize: Kirigami.Units.gridUnit * 0.82
            }

            Text {
                text:           cur ? cur.condition : ""
                color:          "#BFD8F2"
                font.pixelSize: Kirigami.Units.gridUnit * 0.85
                font.italic:    true
                wrapMode:       Text.WordWrap
                Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            }
        }

        // ── Right: Details grid ──────────────────────────────────────────
        GridLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            columns:          2
            columnSpacing:    Kirigami.Units.largeSpacing
            rowSpacing:       Kirigami.Units.smallSpacing * 0.8

            // Helper components defined inline — label + value pair
            // Luftfeuchtigkeit
            Text {
                text:           qsTr("Luftfeuchte")
                color:          Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
            Text {
                text:           cur && cur.humidity !== null
                                ? cur.humidity + " %" : "—"
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }

            // Luftdruck + Trend
            Text {
                text:           qsTr("Luftdruck")
                color:          Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
            Text {
                text: {
                    if (!cur || cur.pressure === null) return "—"
                    return cur.pressure + " " + cur.pressUnit
                }
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }

            // Wind
            Text {
                text:           qsTr("Wind")
                color:          Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
            Text {
                text: {
                    if (!cur) return "—"
                    var s = cur.windDir
                    if (cur.windSpeed !== null) s += "  " + cur.windSpeed + " " + cur.speedUnit
                    return s || "—"
                }
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }

            // Böen (nur wenn vorhanden)
            Text {
                visible:        cur && cur.windGust !== null
                text:           qsTr("Böen")
                color:          Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
            Text {
                visible:        cur && cur.windGust !== null
                text:           cur && cur.windGust !== null
                                ? cur.windGust + " " + cur.speedUnit : ""
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }

            // Sichtweite
            Text {
                text:           qsTr("Sichtweite")
                color:          Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
            Text {
                text:           cur && cur.visibility !== null
                                ? cur.visibility + " " + cur.visUnit : "—"
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }

            // UV-Index
            Text {
                text:           qsTr("UV-Index")
                color:          Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
            Text {
                text: {
                    if (!cur || cur.uvIndex === null) return "—"
                    var s = String(cur.uvIndex)
                    if (cur.uvDescription) s += "  (" + cur.uvDescription + ")"
                    return s
                }
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }

            // Taupunkt
            Text {
                text:           qsTr("Taupunkt")
                color:          Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
            Text {
                text:           cur && cur.dewPoint !== null
                                ? cur.dewPoint + cur.tempUnit : "—"
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
        }
    }
}
