import QtQuick 2.12
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.2 as Controls
import org.kde.kirigami 2.19 as Kirigami
import Qt.labs.platform 1.0 as Labs
import org.kde.plasma.core 2.0 as PlasmaCore
import ".."

ColumnLayout {
    property string cfg_servers: plasmoid.configuration.servers
    property int dialogMode: -1
    Layout.fillWidth: true
    Layout.fillHeight: true
    Component.onCompleted: {
        stationsModel.clear()
        var servers = JSON.parse(cfg_servers)
        for (var i = 0; i < servers.length; i++) {
            stationsModel.append(servers[i])
        }
    }

    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

    Connections {
        target: executable
        function onExited() {
            var formattedText = stdout.trim()
            if (formattedText === cfg_servers) {
                importexportmessage.positive = true
                importexportmessage.text = i18n(
                            "You сonfiguration saved successfully.")
            } else {
                importexportmessage.positive = false
                importexportmessage.text = i18n(
                            "Error, make sure the selected directory is writable!")
            }
            importexportmessage.visible = true
            closetimer.restart()
        }
    }

    Component {
        id: delegateComponent
        Kirigami.SwipeListItem {
            id: listItem
            width: scrollBar.visible ? mainList.width - scrollBar.width : mainList.width
            background: Rectangle {
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                color: listItem.hovered ? Kirigami.Theme.hoverColor : model
                                          && model.index % 2 ? Kirigami.Theme.alternateBackgroundColor : Kirigami.Theme.backgroundColor
                opacity: listItem.hovered ? 0.5 : 1.0
            }
            contentItem: RowLayout {
                clip: true
                Controls.Label {
                    height: Math.max(implicitHeight,
                                     Kirigami.Units.iconSizes.smallMedium)
                    text: model ? model.index + 1 : ""
                    color: listItem.textColor
                }
                Kirigami.ListItemDragHandle {
                    listItem: listItem
                    listView: mainList
                    onMoveRequested: {
                        stationsModel.move(oldIndex, newIndex, 1)
                        cfg_servers = JSON.stringify(getServersArray())
                    }
                }
                Rectangle {
                    id: trackRect
                    clip: true
                    color: "transparent"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    height: parent.height
                    Controls.Label {
                        id: trackName
                        Layout.fillWidth: true
                        anchors.verticalCenter: parent.verticalCenter
                        height: Math.max(implicitHeight,
                                         Kirigami.Units.iconSizes.smallMedium)
                        text: model ? model.name : ""
                        color: listItem.textColor
                        XAnimator {
                            target: trackName
                            from: 0
                            to: -trackName.paintedWidth
                            duration: Math.round(
                                          Math.abs(
                                              to - from) / Kirigami.Units.gridUnit
                                          * (Kirigami.Units.longDuration
                                             + Kirigami.Units.shortDuration))
                            running: listItem.containsMouse
                                     && trackName.width > trackRect.width
                            loops: 1

                            onFinished: {
                                from = trackRect.width
                                if (listItem.containsMouse) {
                                    start()
                                }
                            }
                            onStopped: {
                                from = 0
                                trackName.x = 0
                            }
                        }
                    }
                }
            }
            actions: [

                Kirigami.Action {
                    iconName: "edit-entry"
                    text: i18n("Edit")
                    onTriggered: {
                        mainList.currentIndex = model.index
                        editServer()
                    }
                },
                Kirigami.Action {
                    iconName: checked ? "password-show-on" : "password-show-off"
                    text: checked ? i18n("Hide") : i18n("Show")
                    onTriggered: {
                        model.active = checked
                        cfg_servers = JSON.stringify(getServersArray())
                    }
                    checked: model ? model.active : false
                    checkable: true
                },
                Kirigami.Action {
                    iconName: "delete"
                    text: i18n("Remove")
                    onTriggered: {
                        mainList.model.remove(model.index)
                        cfg_servers = JSON.stringify(getServersArray())
                    }
                }
            ]
        }
    }

    StationsModel {
        id: stationsModel
    }

    ListView {
        id: mainList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        Controls.ScrollBar.vertical: Controls.ScrollBar {
            id: scrollBar
        }

        Rectangle {
            anchors.fill: parent
            z: -1
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false
            color: Kirigami.Theme.backgroundColor
        }
        model: stationsModel
        moveDisplaced: Transition {
            YAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
        delegate: Kirigami.DelegateRecycler {
            sourceComponent: delegateComponent
        }
    }
    Kirigami.InlineMessage {
        property bool positive
        id: importexportmessage
        Layout.fillWidth: true
        visible: false
        showCloseButton: true
        type: positive ? Kirigami.MessageType.Positive : Kirigami.MessageType.Error
    }
    Timer {
        id: closetimer
        running: false
        repeat: false
        interval: 10000
        onTriggered: {
            importexportmessage.visible = false
        }
    }

    RowLayout {
        Controls.Button {
            text: i18n("Add...")
            icon.name: "list-add"
            onClicked: addServer()
        }
        Item {
            Layout.fillWidth: true
        }
        Controls.Button {
            text: i18n("Import...")
            icon.name: "document-import"
            onClicked: openFileDialog.open()
        }
        Controls.Button {
            text: i18n("Export...")
            icon.name: "document-export"
            onClicked: saveFileDialog.open()
        }
    }

    Kirigami.Dialog {
        id: serverDialog
        title: dialogMode == -1 ? i18n("Add Station") : i18n("Edit station")
        padding: Kirigami.Units.largeSpacing
        focus: true
        ColumnLayout {
            Kirigami.FormLayout {
                Controls.TextField {
                    id: serverName
                    Kirigami.FormData.label: i18n("Name:")
                }
                Controls.TextField {
                    id: serverHostname
                    Kirigami.FormData.label: i18n("URL:")
                }
                Controls.CheckBox {
                    id: serverActive
                    checked: true
                    text: i18n("Active")
                }
            }
        }
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        onAccepted: {
            var itemObject = {
                "name": serverName.text,
                "hostname": serverHostname.text,
                "active": serverActive.checked
            }

            if (dialogMode == -1) {
                stationsModel.append(itemObject)
            } else {
                stationsModel.set(dialogMode, itemObject)
            }

            cfg_servers = JSON.stringify(getServersArray())
        }
    }

    Labs.FileDialog {
        id: openFileDialog
        nameFilters: ["ARP Stations Backup (*.arp)"]
        fileMode: Labs.FileDialog.OpenFile
        folder: Labs.StandardPaths.writableLocation(
                    Labs.StandardPaths.HomeLocation)
        onAccepted: {
            openFile(openFileDialog.currentFile)
        }
    }

    Labs.FileDialog {
        id: saveFileDialog
        nameFilters: ["ARP Stations Backup (*.arp)"]
        folder: Labs.StandardPaths.writableLocation(
                    Labs.StandardPaths.HomeLocation)
        fileMode: Labs.FileDialog.SaveFile
        onVisibleChanged: {
            if (visible)
                currentFile = "file: ///" + Labs.StandardPaths.writableLocation(
                            Labs.StandardPaths.HomeLocation) + "/stations.arp"
        }
        onAccepted: saveFile(saveFileDialog.currentFile, cfg_servers)
    }

    function openFile(fileUrl) {
        var request = new XMLHttpRequest()
        request.open("GET", fileUrl, false)
        request.send(null)
        try {
            var servers = JSON.parse(request.responseText)
            stationsModel.clear()
            for (var i = 0; i < servers.length; i++) {
                stationsModel.append(servers[i])
            }
            cfg_servers = JSON.stringify(getServersArray())
            importexportmessage.positive = true
            importexportmessage.text = i18n(
                        "Сonfiguration has been loaded. Click 'Apply' to save changes.")
        } catch (e) {
            importexportmessage.positive = false
            importexportmessage.text = i18n(
                        "Error loading configuration. Try choosing a different file.")
        }
        importexportmessage.visible = true
        closetimer.restart()
    }

    function saveFile(fileUrl, text) {
        var file = fileUrl.toString().replace("file:///", "/")
        executable.exec("echo '" + text + "' > " + file + " && cat " + file)
    }

    function getServersArray() {
        var serversArray = []
        for (var i = 0; i < stationsModel.count; i++) {
            serversArray.push(stationsModel.get(i))
        }
        return serversArray
    }
    function addServer() {
        dialogMode = -1
        serverName.text = ""
        serverHostname.text = ""
        serverActive.checked = true
        serverDialog.visible = true
        serverName.focus = true
    }

    function editServer() {
        dialogMode = mainList.currentIndex
        serverName.text = stationsModel.get(dialogMode).name
        serverHostname.text = stationsModel.get(dialogMode).hostname
        serverActive.checked = stationsModel.get(dialogMode).active
        serverDialog.visible = true
        serverName.focus = true
    }
}
