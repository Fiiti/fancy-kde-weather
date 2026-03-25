import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: dailyRoot

    property var    dailyData: []
    property string tempUnit:  "°C"

    Row {
        anchors.fill: parent
        spacing:      0

        Repeater {
            model: Math.min(dailyRoot.dailyData.length, 7)

            // Per-day column — content centered vertically, not stretched
            Item {
                width:  dailyRoot.width / Math.min(dailyRoot.dailyData.length, 7)
                height: dailyRoot.height

                readonly property var day: dailyRoot.dailyData[index] || {}

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1

                    // Day label
                    Text {
                        text: index === 0
                              ? qsTr("Heute")
                              : (day.dayName ? day.dayName.substring(0, 2) : "—")
                        color:            index === 0 ? "#BFD8F2" : Qt.rgba(1, 1, 1, 0.75)
                        font.pixelSize:   Kirigami.Units.gridUnit * 0.72
                        font.bold:        index === 0
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Weather icon — 50% larger than before (large→huge)
                    Image {
                        source:                 root.weatherIconPath(day.iconCode || "NA")
                        Layout.preferredWidth:  Kirigami.Units.iconSizes.huge
                        Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                        Layout.alignment:       Qt.AlignHCenter
                        fillMode:               Image.PreserveAspectFit
                        smooth:                 true
                    }

                    // Max / Min temperature
                    Text {
                        text: {
                            var hi = (day.tempMax !== null && day.tempMax !== undefined) ? day.tempMax : "—"
                            var lo = (day.tempMin !== null && day.tempMin !== undefined) ? day.tempMin : "—"
                            return hi + "/" + lo + dailyRoot.tempUnit
                        }
                        color:            "white"
                        font.pixelSize:   Kirigami.Units.gridUnit * 0.75
                        font.bold:        true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Precipitation chance (always shown for uniform layout)
                    Text {
                        text:             (day.precipChance !== null && day.precipChance !== undefined)
                                          ? day.precipChance + "%" : "0%"
                        color:            "#5BA4E5"
                        font.pixelSize:   Kirigami.Units.gridUnit * 0.68
                        font.bold:        (day.precipChance || 0) >= 10
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
