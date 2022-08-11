import QtQuick 2.0
import Qt.labs.platform 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import QtQuick.XmlListModel 2.0
import ".."

Item {
    id: configGeneral
    property string cfg_servers: plasmoid.configuration.servers
    property string metadataFilepath: plasmoid.file("", "../metadata.desktop")
    property int dialogMode: -1
    property string serverversion: ""
    property string serverlink: ""
    property string serverpage: ""
    property string appdata: ""
    property string updatepath: ""
    property string tmpfolder: ""

    ServersModel {
        id: serversModel
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
            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            connectSource(cmd)
        }
        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }

    PlasmaCore.DataSource {
        id: update
        engine: "executable"
        connectedSources: []
        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            connectSource(cmd)
        }
        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }

    Connections {
        target: executable
        onExited: {
            if (plasmoid.configuration.version != stdout.replace('\n',
                                                                 ' ').trim()) {
                plasmoid.configuration.version = stdout.replace('\n',
                                                                ' ').trim()
                version.text = i18n("Version: %1",
                                    plasmoid.configuration.version)
            }
        }
    }

    Connections {
        target: update
        onExited: {
            if (exitCode == 0) {
                t.state = "success"
                closenotif.start()
                var cmd = 'kreadconfig5 --file "' + metadataFilepath
                        + '" --group "Desktop Entry" --key "X-KDE-PluginInfo-Version"'
                executable.exec(cmd)
            } else {
                t.state = "fail"
            }
        }
    }
    Timer {
        id: closenotif
        running: false
        repeat: false
        interval: 5000
        onTriggered: {
            anim2.start()
        }
    }

    XmlListModel {
        id: xmlModel
        source: "https://api.kde-look.org/ocs/v1/content/data/1313987"
        query: "/ocs/data/content"

        XmlRole {
            name: "version"
            query: "version/string()"
        }
        XmlRole {
            name: "downloadlink"
            query: "downloadlink1/string()"
        }
        XmlRole {
            name: "homepage"
            query: "homepage/string()"
        }
        onStatusChanged: {
            if (status === XmlListModel.Ready) {
                serverversion = xmlModel.get(0).version
                serverlink = xmlModel.get(0).downloadlink
                serverpage = xmlModel.get(0).homepage
                if (plasmoid.configuration.version != serverversion
                        && updatepath.startsWith(appdata)) {
                    t.state = 'notif'
                } else if (plasmoid.configuration.version != serverversion
                           && !updatepath.startsWith(appdata)) {
                    t.state = "fail"
                } else {

                }
            }
        }
    }

    Component.onCompleted: {
        var cmd = 'kreadconfig5 --file "' + metadataFilepath
                + '" --group "Desktop Entry" --key "X-KDE-PluginInfo-Version"'
        executable.exec(cmd)
        serversModel.clear()
        var servers = JSON.parse(cfg_servers)
        for (var i = 0; i < servers.length; i++) {
            serversModel.append(servers[i])
        }
        var s = StandardPaths.writableLocation(
                    StandardPaths.AppDataLocation).toString()
        appdata = s.slice(0, s.lastIndexOf("/")).replace("file://", "")
        updatepath = metadataFilepath.substr(0, metadataFilepath.indexOf(
                                                 plasmoid.pluginName))
        console.log(updatepath)
        tmpfolder = StandardPaths.writableLocation(
                    StandardPaths.TempLocation).toString().replace("file://",
                                                                   "")
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        anchors.fill: parent
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            SequentialAnimation {
                id: anim
                NumberAnimation {
                    target: t
                    property: "Layout.preferredHeight"
                    duration: units.longDuration
                    from: 0
                    to: updatetext.paintedHeight + units.largeSpacing * 1.5
                    loops: 1
                }
                NumberAnimation {
                    target: t
                    property: "opacity"
                    duration: units.longDuration * 2
                    from: 0
                    to: 1
                    loops: 1
                }
            }
            SequentialAnimation {
                id: anim2
                NumberAnimation {
                    target: t
                    property: "opacity"
                    duration: units.longDuration * 2
                    from: 1
                    to: 0
                    loops: 1
                }
                NumberAnimation {
                    target: t
                    property: "Layout.preferredHeight"
                    duration: units.longDuration
                    from: updatetext.paintedHeight + units.largeSpacing * 1.5
                    to: 0
                    loops: 1
                }
            }
            Rectangle {
                id: t
                visible: false
                opacity: 0
                Layout.fillWidth: true
                Layout.preferredHeight: updatetext.paintedHeight + units.largeSpacing * 1.5
                color: "transparent"
                radius: units.smallSpacing / 2
                onStateChanged: {
                    if (state == "notif") {
                        anim.start()
                    }
                }
                states: [
                    State {
                        name: "notif"
                        PropertyChanges {
                            target: t
                            border.color: PlasmaCore.Theme.highlightColor
                            visible: true
                        }
                        PropertyChanges {
                            target: fill
                            color: PlasmaCore.Theme.highlightColor
                        }
                        PropertyChanges {
                            target: ico
                            source: "update-none"
                        }
                        PropertyChanges {
                            target: updatetext
                            text: i18n("Update is available") + ' (' + serverversion + ').'
                        }
                        PropertyChanges {
                            target: upd
                            visible: true
                        }
                        PropertyChanges {
                            target: cng
                            visible: true
                        }
                    },
                    State {
                        name: "success"
                        PropertyChanges {
                            target: t
                            border.color: PlasmaCore.Theme.positiveTextColor
                            visible: true
                        }
                        PropertyChanges {
                            target: fill
                            color: PlasmaCore.Theme.positiveTextColor
                        }
                        PropertyChanges {
                            target: ico
                            source: "checkbox"
                        }
                        PropertyChanges {
                            target: updatetext
                            text: i18n("Update finished. Please restart the session.")
                            anchors.right: parent.right
                        }
                        PropertyChanges {
                            target: busy
                            visible: false
                            running: false
                        }
                    },
                    State {
                        name: "fail"
                        PropertyChanges {
                            target: t
                            border.color: PlasmaCore.Theme.negativeTextColor
                            visible: true
                        }
                        PropertyChanges {
                            target: fill
                            color: PlasmaCore.Theme.negativeTextColor
                        }
                        PropertyChanges {
                            target: ico
                            source: "dialog-close"
                        }
                        PropertyChanges {
                            target: updatetext
                            text: i18n("Update failed. Make sure that the widget is install in user's home directory.")
                            anchors.right: parent.right
                        }
                        PropertyChanges {
                            target: busy
                            visible: false
                            running: false
                        }
                    }
                ]

                Rectangle {
                    id: fill
                    anchors.fill: parent
                    opacity: 0.2
                    radius: units.smallSpacing / 2 * 0.6
                }

                PlasmaCore.IconItem {
                    id: ico
                    source: ""
                    height: parent.height
                    anchors.left: parent.left
                    anchors.leftMargin: units.smallSpacing
                }

                Label {
                    id: updatetext
                    opacity: 1
                    Layout.fillHeight: true
                    anchors.left: ico.right
                    anchors.leftMargin: units.smallSpacing
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: t.width - ico.width - upd.width - cng.width - units.largeSpacing
                    text: ""
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }
                BusyIndicator {
                    id: busy
                    visible: false
                    running: true
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height / 2
                    anchors.right: upd.left
                }

                Button {
                    visible: false
                    id: upd
                    text: i18n("Update")
                    iconName: "update-none"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: cng.left
                    anchors.rightMargin: units.smallSpacing / 2
                    onClicked: {
                        applyUpdate()
                        this.enabled = false
                    }
                }
                Button {
                    id: cng
                    visible: false
                    text: i18n("Changelog")
                    iconName: "globe"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: units.smallSpacing
                    onClicked: {
                        Qt.openUrlExternally(
                                    "https://store.kde.org/p/1313987#updates-panel")
                    }
                }
            }
        }
        RowLayout {
            Layout.fillHeight: true
            TableView {
                id: serversTable
                model: serversModel
                Layout.fillHeight: true
                Layout.fillWidth: true
                TableViewColumn {
                    title: "👁"
                    role: "active"
                    horizontalAlignment: Text.AlignHCenter
                    width: 30
                    delegate: CheckBox {
                        anchors.fill: parent
                        anchors.centerIn: parent
                        checked: model.active
                        onVisibleChanged: if (visible)
                                              checked = styleData.value
                        onClicked: {
                            model.active = checked
                            cfg_servers = JSON.stringify(getServersArray())
                        }
                    }
                }

                TableViewColumn {
                    role: "name"
                    title: i18n("Name")
                    width: serversTable.width - 35
                }
                onDoubleClicked: {
                    editServer()
                }
                onClicked: {
                    edit.enabled = true
                    remove.enabled = true
                    moveUp.enabled = true
                    moveDown.enabled = true
                }
            }
            ColumnLayout {
                id: buttonsColumn
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                Layout.fillHeight: true
                Button {
                    text: i18n("Add")
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    iconName: "list-add"
                    onClicked: {
                        addServer()
                    }
                }
                Button {
                    id: edit
                    text: i18n("Edit")
                    iconName: "edit-entry"
                    Layout.fillWidth: true
                    enabled: false
                    onClicked: {
                        editServer()
                    }
                }
                Button {
                    id: remove
                    text: i18n("Remove")
                    iconName: "list-remove"
                    Layout.fillWidth: true
                    enabled: false
                    onClicked: {
                        if (serversTable.currentRow == -1)
                            return
                        serversTable.model.remove(serversTable.currentRow)
                        cfg_servers = JSON.stringify(getServersArray())
                    }
                }
                Button {
                    id: moveUp
                    text: i18n("Move up")
                    iconName: "go-up"
                    enabled: false
                    Layout.fillWidth: true
                    onClicked: {
                        if (serversTable.currentRow == -1
                                || serversTable.currentRow == 0) {
                            this.enabled == false
                            return
                        }
                        serversTable.model.move(serversTable.currentRow,
                                                serversTable.currentRow - 1, 1)
                        serversTable.selection.clear()
                        serversTable.selection.select(
                                    serversTable.currentRow - 1)
                        cfg_servers = JSON.stringify(getServersArray())
                    }
                }
                Button {
                    id: moveDown
                    text: i18n("Move down")
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                    iconName: "go-down"
                    Layout.fillWidth: true
                    enabled: false
                    onClicked: {
                        if (serversTable.currentRow == -1
                                || serversTable.currentRow == serversTable.model.count - 1) {
                            this.enabled == false
                            return
                        }
                        serversTable.model.move(serversTable.currentRow,
                                                serversTable.currentRow + 1, 1)
                        serversTable.selection.clear()
                        serversTable.selection.select(
                                    serversTable.currentRow + 1)
                        cfg_servers = JSON.stringify(getServersArray())
                    }
                }
                Label {
                    id: version
                    text: i18n("Version: %1", plasmoid.configuration.version)
                    verticalAlignment: Text.AlignBottom
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                }
            }
        }
    }

    Dialog {
        id: serverDialog
        visible: false
        title: i18n("Station")
        standardButtons: StandardButton.Cancel | StandardButton.Save

        onAccepted: {
            var itemObject = {
                "name": serverName.text,
                "hostname": serverHostname.text,
                "active": serverActive.checked
            }

            if (dialogMode == -1) {
                serversModel.append(itemObject)
            } else {
                serversModel.set(dialogMode, itemObject)
            }

            cfg_servers = JSON.stringify(getServersArray())
        }

        ColumnLayout {
            GridLayout {
                columns: 2

                Label {
                    text: i18n("Name:")
                }

                TextField {
                    id: serverName
                    Layout.minimumWidth: theme.mSize(
                                             theme.defaultFont).width * 40
                }

                Label {
                    text: i18n("Station URL:")
                }

                TextField {
                    id: serverHostname
                    Layout.minimumWidth: theme.mSize(
                                             theme.defaultFont).width * 40
                }

                Label {
                    text: ""
                }

                CheckBox {
                    id: serverActive
                    text: i18n("Active")
                }
            }
        }
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
        dialogMode = serversTable.currentRow

        serverName.text = serversModel.get(dialogMode).name
        serverHostname.text = serversModel.get(dialogMode).hostname
        serverActive.checked = serversModel.get(dialogMode).active
        serverDialog.visible = true
        serverName.focus = true
    }

    function getServersArray() {
        var serversArray = []
        for (var i = 0; i < serversModel.count; i++) {
            serversArray.push(serversModel.get(i))
        }
        return serversArray
    }

    function applyUpdate() {
        updatetext.text = i18n("Updating...")
        busy.visible = true
        update.exec("wget -O " + tmpfolder + "/" + plasmoid.pluginName
                    + ".tar.gz " + serverlink + " && tar -C " + updatepath
                    + "/ -xvzf " + tmpfolder + "/" + plasmoid.pluginName
                    + ".tar.gz && rm " + tmpfolder + "/" + plasmoid.pluginName + ".tar.gz")
    }
}
