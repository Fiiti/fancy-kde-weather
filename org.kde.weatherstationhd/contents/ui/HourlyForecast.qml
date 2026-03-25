import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: hourlyRoot

    property var    hourlyData: []
    property string tempUnit:   "°C"

    implicitHeight: hourlyRow.implicitHeight + Kirigami.Units.smallSpacing

    QQC2.ScrollView {
        anchors.fill: parent
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AsNeeded
        QQC2.ScrollBar.vertical.policy:   QQC2.ScrollBar.AlwaysOff
        clip: true

        Row {
            id:      hourlyRow
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: hourlyRoot.hourlyData

                // Per-hour cell
                ColumnLayout {
                    width:   Kirigami.Units.gridUnit * 3.6
                    spacing: 2

                    // Hour label
                    Text {
                        text:               _formatHour(modelData.time)
                        color:              Qt.rgba(1, 1, 1, 0.65)
                        font.pixelSize:     Kirigami.Units.gridUnit * 0.72
                        Layout.alignment:   Qt.AlignHCenter
                    }

                    // Weather icon (+50% size)
                    Image {
                        source:                 root.weatherIconPath(modelData.iconCode)
                        Layout.preferredWidth:  Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
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

                    // Precipitation chance (only if > 0)
                    Text {
                        visible:          modelData.precipChance !== null
                                          && modelData.precipChance > 0
                        text:             (modelData.precipChance || 0) + "%"
                        color:            "#5BA4E5"
                        font.pixelSize:   Kirigami.Units.gridUnit * 0.72
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    // VC time format: "HH:MM:SS" (e.g. "10:00:00")
    function _formatHour(isoStr) {
        if (!isoStr || isoStr.length < 5) return "—"
        return isoStr.substring(0, 5)
    }
}
