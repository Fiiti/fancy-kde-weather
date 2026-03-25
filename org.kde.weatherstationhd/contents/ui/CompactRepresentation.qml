import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    Layout.minimumWidth:  row.implicitWidth + Kirigami.Units.smallSpacing * 2
    Layout.minimumHeight: Kirigami.Units.iconSizes.small

    RowLayout {
        id: row
        anchors {
            fill: parent
            leftMargin:  Kirigami.Units.smallSpacing
            rightMargin: Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.smallSpacing

        Image {
            id: conditionIcon
            readonly property int iconSize: Math.min(compactRoot.height,
                                                     Kirigami.Units.iconSizes.medium)
            source: root.weatherData
                    ? root.weatherIconPath(root.weatherData.current.iconCode)
                    : root.weatherIconPath("NA")
            Layout.preferredWidth:  iconSize
            Layout.preferredHeight: iconSize
            fillMode:               Image.PreserveAspectFit
            smooth:                 true
        }

        Text {
            id: tempLabel
            text: {
                if (root.loading)      return "…"
                if (!root.weatherData) return "—"
                var c = root.weatherData.current
                return c.temperature !== null
                       ? (c.temperature + c.tempUnit)
                       : "—"
            }
            color:           Kirigami.Theme.textColor
            font.pixelSize:  Math.max(Math.round(compactRoot.height * 0.45), 11)
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked:    root.expanded = !root.expanded
    }
}
