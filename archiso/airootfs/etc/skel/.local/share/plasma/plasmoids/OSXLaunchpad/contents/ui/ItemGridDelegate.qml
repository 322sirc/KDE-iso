/***************************************************************************
 *   Copyright (C) 2015 by Eike Hein <hein@kde.org>                        *
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

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0
import QtGraphicalEffects 1.0

import "../code/tools.js" as Tools

Item {
    id: item

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    property bool showLabel: true

    readonly property int itemIndex: model.index
    readonly property url url: model.url != undefined ? model.url : ""
    property bool pressed: false
    readonly property bool hasActionList: ((model.favoriteId != null)
                                           || (("hasActionList" in model) && (model.hasActionList == true)))

    Accessible.role: Accessible.MenuItem
    Accessible.name: model.display

    function openActionMenu(x, y) {
        var actionList = hasActionList ? model.actionList : [];
        Tools.fillActionMenu(i18n, actionMenu, actionList, GridView.view.model.favoritesModel, model.favoriteId);
        actionMenu.visualParent = item;
        actionMenu.open(x, y);
    }

    function actionTriggered(actionId, actionArgument) {
        Tools.triggerAction(plasmoid, GridView.view.model, model.index, actionId, actionArgument);
    }

    Rectangle{
        id: box
        height: parent.height // - 10
        width:  parent.width  // - 10
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        //color:"red"
        //opacity: 0.4
        color:"transparent"
    }
    PlasmaCore.IconItem {
        id: icon
        y: iconSize*0.2
        anchors.horizontalCenter: box.horizontalCenter
        //anchors.verticalCenter:   box.verticalCenter
        width: iconSize
        height: width
        animated: false
        usesPlasmaTheme: item.GridView.view.usesPlasmaTheme
        source: model.decoration
    }

    PlasmaComponents.Label {
        id: label

        visible: showLabel

        anchors {
            top: icon.bottom
            topMargin: units.smallSpacing
            left: parent.left
            leftMargin: highlightItemSvg.margins.left
            right: parent.right
            rightMargin: highlightItemSvg.margins.right
        }

        horizontalAlignment: Text.AlignHCenter

        maximumLineCount: 2
        elide: Text.ElideRight
        wrapMode: Text.Wrap

        color: plasmoid.configuration.invertColors ? "black" : "#f1f1f1" // FIXME TODO: Respect theming?

        text: ("name" in model ? model.name : model.display)
        layer.enabled: true
        layer.effect: DropShadow {
            verticalOffset: 1
            horizontalOffset: 1
            color: plasmoid.configuration.invertColors ? "#00000000" : "#aa000000"
            radius: 2
            samples: 5
        }
    }

    Keys.onPressed: {
        if (event.key == Qt.Key_Menu && hasActionList) {
            event.accepted = true;
            openActionMenu(item);
        } else if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return)) {
            event.accepted = true;
            GridView.view.model.trigger(index, "", null);
            root.toggle();

        }
    }
}
