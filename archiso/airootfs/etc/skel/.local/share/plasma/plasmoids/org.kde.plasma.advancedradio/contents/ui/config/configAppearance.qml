import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import org.kde.kquickcontrols 2.0 as KQuickControls
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: configAppearance
    Layout.fillWidth: true
    property string cfg_icon: plasmoid.configuration.icon
    property alias cfg_fontColor: fontColor.color
    property bool cfg_transback: plasmoid.configuration.transback
    property bool cfg_Notification: plasmoid.configuration.Notification
    property bool cfg_panel: plasmoid.configuration.panel
    property alias cfg_panelWidth: panelWidth.value
    property bool cfg_border: plasmoid.configuration.border
    property bool cfg_minimize: plasmoid.configuration.minimize
    property bool cfg_showStation: plasmoid.configuration.showStation
    ColumnLayout {
        RowLayout {
            Label {
                text: i18n("Panel view")
            }

            ComboBox {
                Layout.fillWidth: true
                id: viewBox
                model: [i18n("icon"), i18n("track name")]
                onCurrentIndexChanged: currentIndex == 0 ? cfg_panel = false : cfg_panel = true
                currentIndex: cfg_panel
            }
        }
        RowLayout {
            Label {
                text: i18n("Panel width") + " " + panelWidth.value
                visible: viewBox.currentIndex == 1
            }
            Slider {
                id: panelWidth
                stepSize: 1
                minimumValue: 180
                maximumValue: 1000
                Layout.fillWidth: true
                visible: viewBox.currentIndex == 1
            }
        }
        RowLayout {
            CheckBox {
                text: i18n("Show border")
                checked: cfg_border
                visible: viewBox.currentIndex == 1
                onClicked: {
                    cfg_border = checked
                }
            }
        }
        RowLayout {
            CheckBox {
                text: i18n("Minimize to icon on stop")
                checked: cfg_minimize
                visible: viewBox.currentIndex == 1
                onClicked: {
                    cfg_minimize = checked
                }
            }
        }

        RowLayout {
            Label {
                text: i18n("Icon:")
                visible: viewBox.currentIndex == 0
            }

            IconPicker {
                currentIcon: cfg_icon
                defaultIcon: "audio-radio-symbolic"
                onIconChanged: cfg_icon = iconName
                enabled: true
                visible: viewBox.currentIndex == 0
            }
        }

        ColumnLayout {

            CheckBox {
                text: i18n("Show notification on track change")
                checked: cfg_Notification
                onClicked: {
                    cfg_Notification = checked
                }
            }
            CheckBox {
                visible: false
                text: i18n("Show station name if track is not recognized")
                checked: cfg_showStation
                onClicked: {
                    cfg_showStation = checked
                }
            }
            CheckBox {
                text: i18n("Disable background for desktop representation")
                checked: cfg_transback
                onClicked: {
                    cfg_transback = checked
                }
            }
        }
        GridLayout {
            columns: 3
            Label {
                text: i18n("Font Color:")
                visible: cfg_transback
            }

            KQuickControls.ColorButton {
                id: fontColor
                showAlphaChannel: false
                onColorChanged: {

                }
                visible: cfg_transback
            }
            Button {
                text: i18n("Set Default")
                iconName: "edit-clear"
                visible: cfg_transback
                onClicked: {
                    fontColor.color = PlasmaCore.ColorScope.textColor
                }
            }
        }
    }
}
