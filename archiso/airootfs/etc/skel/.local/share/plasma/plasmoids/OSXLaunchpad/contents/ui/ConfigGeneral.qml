/***************************************************************************
 *   Copyright (C) 2014 by Eike Hein <hein@kde.org>                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons
import org.kde.draganddrop 2.0 as DragDrop
import org.kde.plasma.private.kicker 0.1 as Kicker

Item {
    id: configGeneral

    width: childrenRect.width
    height: childrenRect.height

    property string cfg_icon: plasmoid.configuration.icon
    property bool cfg_useCustomButtonImage: plasmoid.configuration.useCustomButtonImage
    property string cfg_customButtonImage: plasmoid.configuration.customButtonImage


    property alias cfg_useCustomSizeGrid: useCustomSizeGrid.checked
    property alias cfg_iconSize:      iconSize.value
    property alias cfg_numberColumns: numberColumns.value
    property alias cfg_numberRows:    numberRows.value
    property alias cfg_spaceWidth:    spaceWidth.value
    property alias cfg_spaceHeight:   spaceHeight.value
    property alias cfg_dimming:       dimming.value
    property alias cfg_searchopacity: searchopacity.value
    property alias  cfg_backgroundImageCheckBox: backgroundImageCheckBox.checked
    property string cfg_backgroundImage: backgroundImage.text
    property alias cfg_animateScroll: animateScroll.checked
    property alias cfg_animateScrollSpeed: animateScrollSpeed.value

    ColumnLayout {
        anchors.left: parent.left

        RowLayout {
            spacing: units.smallSpacing

            Label {
                text: i18n("Icon:")
            }

            Button {
                id: iconButton
                Layout.minimumWidth: previewFrame.width + units.smallSpacing * 2
                Layout.maximumWidth: Layout.minimumWidth
                Layout.minimumHeight: previewFrame.height + units.smallSpacing * 2
                Layout.maximumHeight: Layout.minimumWidth

                DragDrop.DropArea {
                    id: dropArea

                    property bool containsAcceptableDrag: false

                    anchors.fill: parent

                    onDragEnter: {
                        // Cannot use string operations (e.g. indexOf()) on "url" basic type.
                        var urlString = event.mimeData.url.toString();

                        // This list is also hardcoded in KIconDialog.
                        var extensions = [".png", ".xpm", ".svg", ".svgz"];
                        containsAcceptableDrag = urlString.indexOf("file:///") === 0 && extensions.some(function (extension) {
                            return urlString.indexOf(extension) === urlString.length - extension.length; // "endsWith"
                        });

                        if (!containsAcceptableDrag) {
                            event.ignore();
                        }
                    }
                    onDragLeave: containsAcceptableDrag = false

                    onDrop: {
                        if (containsAcceptableDrag) {
                            // Strip file:// prefix, we already verified in onDragEnter that we have only local URLs.
                            iconDialog.setCustomButtonImage(event.mimeData.url.toString().substr("file://".length));
                        }
                        containsAcceptableDrag = false;
                    }
                }

                KQuickAddons.IconDialog {
                    id: iconDialog

                    function setCustomButtonImage(image) {
                        cfg_customButtonImage = image || cfg_icon || "start-here-kde"
                        cfg_useCustomButtonImage = true;
                    }

                    onIconNameChanged: setCustomButtonImage(iconName);
                }

                // just to provide some visual feedback, cannot have checked without checkable enabled
                checkable: true
                checked: dropArea.containsAcceptableDrag
                onClicked: {
                    checked = Qt.binding(function() { // never actually allow it being checked
                        return iconMenu.status === PlasmaComponents.DialogStatus.Open || dropArea.containsAcceptableDrag;
                    })

                    iconMenu.open(0, height)
                }

                PlasmaCore.FrameSvgItem {
                    id: previewFrame
                    anchors.centerIn: parent
                    imagePath: plasmoid.location === PlasmaCore.Types.Vertical || plasmoid.location === PlasmaCore.Types.Horizontal
                               ? "widgets/panel-background" : "widgets/background"
                    width: units.iconSizes.large + fixedMargins.left + fixedMargins.right
                    height: units.iconSizes.large + fixedMargins.top + fixedMargins.bottom

                    PlasmaCore.IconItem {
                        anchors.centerIn: parent
                        width: units.iconSizes.large
                        height: width
                        source: cfg_useCustomButtonImage ? cfg_customButtonImage : cfg_icon
                    }
                }
            }

            // QQC Menu can only be opened at cursor position, not a random one
            PlasmaComponents.ContextMenu {
                id: iconMenu
                visualParent: iconButton

                PlasmaComponents.MenuItem {
                    text: i18nc("@item:inmenu Open icon chooser dialog", "Choose...")
                    icon: "document-open-folder"
                    onClicked: iconDialog.open()
                }
                PlasmaComponents.MenuItem {
                    text: i18nc("@item:inmenu Reset icon to default", "Clear Icon")
                    icon: "edit-clear"
                    onClicked: {
                        cfg_useCustomButtonImage = false;
                    }
                }
            }
        }


        RowLayout{
            Layout.fillWidth: true
            Label {
                Layout.leftMargin: units.smallSpacing
                text: i18n("Size of icons")
            }
            SpinBox{
                id: iconSize
                minimumValue: 24
                maximumValue: 256
                stepSize: 4
            }
        }

        RowLayout{
            ColumnLayout {
                RowLayout{
                    Layout.fillWidth: true
                    SpinBox{
                        id: spaceWidth
                        minimumValue: 10
                        maximumValue: 128
                        stepSize: 4
                    }
                    Label {
                        Layout.leftMargin: units.smallSpacing
                        text: i18n("Space between columns")
                    }
                }

                RowLayout{
                    Layout.fillWidth: true
                    // /flat: true
                    SpinBox{
                        id: spaceHeight
                        minimumValue: 10
                        maximumValue: 128
                        stepSize: 4
                    }
                    Label {
                        Layout.leftMargin: units.smallSpacing
                        text: i18n("Space between rows")
                    }
                }
            }
        }

        RowLayout{
            spacing: units.smallSpacing
            CheckBox{
                id: useCustomSizeGrid
                text:  "Enable custom grid"
            }

        }
        GroupBox {
            title: i18n("Grid")
            flat: true
            enabled: useCustomSizeGrid.checked
            ColumnLayout {
                RowLayout{
                    Layout.fillWidth: true
                    SpinBox{
                        id: numberColumns
                        minimumValue: 4
                        maximumValue: 20
                    }
                    Label {
                        Layout.leftMargin: units.smallSpacing
                        text: i18n("Number of columns")
                    }
                }

                RowLayout{
                    Layout.fillWidth: true
                    SpinBox{
                        id: numberRows
                        minimumValue: 4
                        maximumValue: 20
                    }
                    Label {
                        Layout.leftMargin: units.smallSpacing
                        text: i18n("Number of rows")
                    }
                }
            }
        }
        RowLayout{

                        Row{
                    spacing: units.smallSpacing
                   CheckBox {
                        id: backgroundImageCheckBox
                        checked: !backgroundColorCheckBox.checked
                        text: i18n("Image background:")
                        onCheckedChanged: {
                            backgroundColorCheckBox.checked = !backgroundImageCheckBox.checked
                        }
                    }

                    TextField {
                        id: backgroundImage
                        placeholderText: "Select image"
                        text: cfg_backgroundImage
                        readOnly : true
                    }

                    Button {
                        id: imageButton
                        implicitWidth: height
                        PlasmaCore.IconItem {
                            anchors.fill: parent
                            source: "document-open-folder"
                            PlasmaCore.ToolTipArea {
                                anchors.fill: parent
                                subText: "Select image"
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {fileDialog.open() }
                        }
                    }
                    FileDialog {
                        id: fileDialog
                        selectMultiple : false
                        title: "Pick a image file"
                        nameFilters: [ "Image files (*.jpg *.png *.jpeg)", "All files (*)" ]
                        onAccepted: {
                            backgroundImage.text= fileDialog.fileUrls[0]
                            cfg_backgroundImage = backgroundImage.text
                        }
                    }
                }
        }
                GroupBox {
            Layout.fillWidth: true

            title: i18n("Effects")

            flat: true

            ColumnLayout {
                CheckBox {
                    id: animateScroll

                    text: i18n("Animate page switching")
                }

                RowLayout {
                    visible: animateScroll.checked
                    Label {
                        text: i18n("Slow")
                    }

                    Slider {
                        id: animateScrollSpeed

                        maximumValue: 550

                        minimumValue: 150

                        stepSize: 100

                        tickmarksEnabled: true

                        wheelEnabled: false
                    }

                    Label {
                        text: i18n("Fast")
                    }
                }
            }
        }

                    RowLayout{
        Layout.fillWidth: true
        Label {
            text: i18n("Dimming:")
        }
        Slider{
            id: dimming
            minimumValue: 0
            maximumValue: 100
            stepSize: 10
            implicitWidth: 100
        }
        Label {
            text: i18n(dimming.value + "%");
        }
    }

                RowLayout{
        Layout.fillWidth: true
        Label {
            text: i18n("Search Opacity:")
        }
        Slider{
            id: searchopacity
            minimumValue: 0
            maximumValue: 100
            stepSize: 10
            implicitWidth: 100
        }
        Label {
            text: i18n(searchopacity.value + "%");
        }
    }
  }
}
