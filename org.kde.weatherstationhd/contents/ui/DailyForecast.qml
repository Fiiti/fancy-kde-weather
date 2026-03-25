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

            // Per-day column
            ColumnLayout {
                width:   dailyRoot.width / Math.min(dailyRoot.dailyData.length, 7)
                height:  dailyRoot.height
                spacing: 2

                readonly property var day: dailyRoot.dailyData[index] || {}

                // Day label: "Heute" for index 0, short name otherwise
                Text {
                    text: index === 0
                          ? qsTr("Heute")
                          : (day.dayName ? day.dayName.substring(0, 2) : "—")
                    color:            index === 0 ? "#BFD8F2" : Qt.rgba(1, 1, 1, 0.75)
                    font.pixelSize:   Kirigami.Units.gridUnit * 0.72
                    font.bold:        index === 0
                    Layout.alignment: Qt.AlignHCenter
                }

                // Weather icon (2× size)
                Image {
                    source:                 root.weatherIconPath(day.iconCode || "NA")
                    Layout.preferredWidth:  Kirigami.Units.iconSizes.large
                    Layout.preferredHeight: Kirigami.Units.iconSizes.large
                    Layout.alignment:       Qt.AlignHCenter
                    fillMode:               Image.PreserveAspectFit
                    smooth:                 true
                }

                // Precipitation chance (empty space if 0 to keep alignment)
                Text {
                    text: (day.precipChance !== null && day.precipChance !== undefined
                           && day.precipChance > 0)
                          ? day.precipChance + "%" : " "
                    color:            "#5BA4E5"
                    font.pixelSize:   Kirigami.Units.gridUnit * 0.68
                    Layout.alignment: Qt.AlignHCenter
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
            }
        }
    }
}
