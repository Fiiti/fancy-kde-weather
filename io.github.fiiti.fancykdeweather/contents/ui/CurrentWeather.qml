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
        spacing: Kirigami.Units.gridUnit

        // ── Block 1: Icon + Condition + Stadtname ───────────────────────
        ColumnLayout {
            Layout.alignment:  Qt.AlignTop
            Layout.topMargin:  -Kirigami.Units.smallSpacing
            Layout.leftMargin: -Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.preferredWidth:  Kirigami.Units.gridUnit * 7.0
                Layout.preferredHeight: Kirigami.Units.gridUnit * 7.0
                Layout.minimumWidth:    Kirigami.Units.gridUnit * 5.0
                Layout.minimumHeight:   Kirigami.Units.gridUnit * 5.0

                Image {
                    anchors.fill: parent
                    source:       cur ? root.weatherIconPath(cur.iconCode) : ""
                    fillMode:     Image.PreserveAspectFit
                    smooth:       true
                }

                Text {
                    anchors.bottom:           parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:           cur ? cur.condition : ""
                    color:          "white"
                    font.pixelSize: Kirigami.Units.gridUnit * 0.82
                    font.italic:    true
                    style:          Text.Outline
                    styleColor:     "#99000000"
                    wrapMode:       Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width:          parent.width
                }
            }

            Text {
                text:           cur ? (cur.city || "") : ""
                color:          "#BFD8F2"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
                font.bold:      true
                Layout.alignment:    Qt.AlignHCenter
                Layout.maximumWidth: Kirigami.Units.gridUnit * 8
                wrapMode:       Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // ── Block 2: Temperatur + Gefühlt ────────────────────────────────
        ColumnLayout {
            Layout.alignment:   Qt.AlignTop
            Layout.minimumWidth: Kirigami.Units.gridUnit * 4.0
            spacing: Kirigami.Units.smallSpacing

            Text {
                text: {
                    if (!cur) return "—"
                        return cur.temperature !== null
                        ? (cur.temperature + cur.tempUnit)
                        : "—"
                }
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 2.8
                font.bold:      true
            }

            Text {
                visible:        cur && cur.feelsLike !== null
                text:           cur ? i18n("Feels like %1%2", cur.feelsLike, cur.tempUnit)
                : ""
                color:          Qt.rgba(1, 1, 1, 0.75)
                font.pixelSize: Kirigami.Units.gridUnit * 0.82
            }
        }

        // ── Block 3: Detail-Grid ─────────────────────────────────────────
        GridLayout {
            Layout.alignment:    Qt.AlignTop
            Layout.fillWidth:    true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 8.0
            columns:             2
            columnSpacing:       Kirigami.Units.largeSpacing
            rowSpacing:          Kirigami.Units.smallSpacing * 0.8

            // Humidity
            Text {
                text:           i18n("Humidity")
                color:          Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
            Text {
                text:           cur && cur.humidity !== null
                ? cur.humidity + " %" : "—"
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }

            // Pressure
            Text {
                text:           i18n("Pressure")
                color:          Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
            Text {
                text:           cur && cur.pressure !== null
                ? cur.pressure + " " + cur.pressUnit : "—"
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }

            // Wind
            Text {
                text:           i18n("Wind")
                color:          Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
            Text {
                text:           cur && cur.windSpeed !== null
                ? cur.windDir + " " + cur.windSpeed + " " + cur.speedUnit : "—"
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }

            // Gusts
            Text {
                visible:        cur && cur.windGust !== null
                text:           i18n("Gusts")
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

            // Visibility
            Text {
                text:           i18n("Visibility")
                color:          Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }
            Text {
                text:           cur && cur.visibility !== null
                ? cur.visibility + " " + cur.visUnit : "—"
                color:          "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.78
            }

            // UV Index
            Text {
                text:           i18n("UV Index")
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

            // Dew point
            Text {
                text:           i18n("Dew point")
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
