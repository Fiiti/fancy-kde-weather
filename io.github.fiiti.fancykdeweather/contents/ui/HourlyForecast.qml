import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: hourlyRoot

    property var    hourlyData: []
    property string tempUnit:   "°C"

    Row {
        id:           hourlyRow
        anchors.fill: parent
        spacing:      0

        Repeater {
            model: hourlyRoot.hourlyData

            // Per-hour cell — width scales with widget width
            Item {
                width:  hourlyRoot.width / Math.max(hourlyRoot.hourlyData.length, 1)
                height: hourlyRow.height

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    // Hour label
                    Text {
                        text:             _formatHour(modelData.time)
                        color:            Qt.rgba(1, 1, 1, 0.65)
                        font.pixelSize:   Kirigami.Units.gridUnit * 0.72
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Weather icon
                    Image {
                        source:                 root.weatherIconPath(modelData.iconCode)
                        Layout.preferredWidth:  Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: Kirigami.Units.iconSizes.large
                        Layout.alignment:       Qt.AlignHCenter
                        fillMode:               Image.PreserveAspectFit
                        smooth:                 true
                    }

                    // Temperature
                    Text {
                        text:             modelData.temperature !== null
                                          ? (modelData.temperature + hourlyRoot.tempUnit)
                                          : "—"
                        color:            "white"
                        font.pixelSize:   Kirigami.Units.gridUnit * 0.82
                        font.bold:        true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Precipitation chance (always shown for uniform layout)
                    Text {
                        text:             (modelData.precipChance !== null && modelData.precipChance !== undefined)
                                          ? modelData.precipChance + "%" : "0%"
                        color:            (modelData.precipChance || 0) > 0 ? "#5BA4E5" : "#666666"
                        font.pixelSize:   Kirigami.Units.gridUnit * 0.72
                        font.bold:        (modelData.precipChance || 0) >= 10
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    // VC time format: "HH:MM:SS" (e.g. "10:00:00") → "HH:MM"
    function _formatHour(isoStr) {
        if (!isoStr || isoStr.length < 5) return "—"
        return isoStr.substring(0, 5)
    }
}
