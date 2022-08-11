import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.plasma.core 2.0 as PlasmaCore
import QtMultimedia 5.8
import ".."

Item {
    id: configSearch

    SearchModel {
        id: searchModel
    }
    ServersModel {
        id: serversModel
    }
    property var items: ["fr", "de", "nl"]
    property var server: ""
    property string cfg_servers: plasmoid.configuration.servers
    property int limit: 500
    property int offset: 0
    property string currentUrl
    property int stat: 1
    property string cfg_version: plasmoid.configuration.version

    property var rootthis: root.parent
    function getServer() {
        var items = configSearch.items
        var item = items[Math.floor(Math.random() * items.length)]
        configSearch.server = item
    }
    Timer {
        id: timerconnect
        repeat: false
        running: true
        interval: 5000
    }

    function getStations(by, val) {
        configSearch.offset = 0
        var item = configSearch.server
        busy.running = true
        infoModel.clear()
        playButton.enabled = false
        addButton.enabled = false
        gettext.visible = true
        gettext.text = i18n("Get list of stations\nPlease wait...")
        view.enabled = false
        var timer = timerconnect
        timer.triggered.connect(function () {
            xmlhttp.abort()
            configSearch.items.splice(configSearch.items.indexOf(item), 1)
            if (configSearch.items.length < 1) {
                configSearch.items = ["fr", "de", "nl"]
            }
            getServer()
            getStations()
        })
        function setHeaders(xmlhttp) {
            xmlhttp.setRequestHeader("User-Agent",
                                     "AdvancedRadio/" + cfg_version)
        }
        var xmlhttp = new XMLHttpRequest
        var url = typeof (by) != "undefined" && by
                !== null ? "https://" + item + "1.api.radio-browser.info/json/stations/" + by
                           + "/" + val + "?hidebroken=true&limit=" + configSearch.limit
                           + "&offset=" + configSearch.offset : "https://"
                           + item + "1.api.radio-browser.info/json/stations?hidebroken=true&limit="
                           + configSearch.limit + "&offset=" + configSearch.offset
        xmlhttp.open("GET", url)
        setHeaders(xmlhttp)
        xmlhttp.onreadystatechange = function () {
            if (xmlhttp.readyState === xmlhttp.DONE) {
                if (xmlhttp.status == 200) {
                    timer.running = false
                    configSearch.currentUrl = url.split("?")[0]
                    var myArr = JSON.parse(xmlhttp.responseText)
                    searchModel.clear()
                    var servers = myArr
                    for (var i = 0; i < servers.length; i++) {
                        searchModel.append(servers[i])
                    }
                    busy.running = false
                    gettext.visible = servers.length > 0 ? false : true
                    gettext.text = servers.length
                            == 0 ? i18n("Nothing found\nTry changing your query") : i18n(
                                       "Get list of stations\nPlease wait...")
                    view.enabled = true
                    if (servers.length == 0) {
                        searchDialog.open()
                    }
                    configSearch.stat = 1
                }
            }
        }

        xmlhttp.send()
    }
    function loadMore() {
        configSearch.stat = 0
        function setHeaders(xmlhttp) {
            xmlhttp2.setRequestHeader("User-Agent",
                                      "AdvancedRadio/" + cfg_version)
        }
        var xmlhttp2 = new XMLHttpRequest
        var url = configSearch.currentUrl.split(
                    "?")[0] + "?hidebroken=true&limit=" + configSearch.limit
                + "&offset=" + configSearch.offset
        xmlhttp2.open("GET", url)
        setHeaders(xmlhttp2)
        xmlhttp2.onreadystatechange = function () {
            if (xmlhttp2.readyState == xmlhttp2.DONE) {
                if (xmlhttp2.status == 200) {
                    configSearch.currentUrl = url
                    var myArr = JSON.parse(xmlhttp2.responseText)
                    var servers = myArr
                    if (servers.length > 0) {
                        for (var i = 0; i < servers.length; i++) {
                            searchModel.append(servers[i])
                        }
                        configSearch.stat = 1
                    }
                }
            }
        }

        xmlhttp2.send()
    }

    Component.onCompleted: {
        serversModel.clear()
        var servers = JSON.parse(cfg_servers)

        for (var i = 0; i < servers.length; i++) {
            serversModel.append(servers[i])
        }
        configSearch.stat = 0
        getServer()
        getStations()
    }

    ListModel {
        id: infoModel
        ListElement {
            name: " "
            value: " "
        }
    }
    function loadInfo() {

        infoModel.append({
                             "name": i18n("Name:"),
                             "value": searchModel.get(
                                          searchTable.currentRow).name
                         })

        infoModel.append({
                             "name": i18n("Url:"),
                             "value": searchModel.get(
                                          searchTable.currentRow).url_resolved
                         })
        infoModel.append({
                             "name": i18n("Server status:"),
                             "value": searchModel.get(
                                          searchTable.currentRow).status
                         })
        infoModel.append({
                             "name": i18n("Codec:"),
                             "value": searchModel.get(
                                          searchTable.currentRow).codec
                         })
        infoModel.append({
                             "name": i18n("Bitrate:"),
                             "value": searchModel.get(
                                          searchTable.currentRow).bitrate.toString(
                                          ) + i18n("kb/s")
                         })
        infoModel.append({
                             "name": i18n("Country:"),
                             "value": searchModel.get(
                                          searchTable.currentRow).country
                         })
        infoModel.append({
                             "name": i18n("Language:"),
                             "value": searchModel.get(
                                          searchTable.currentRow).language
                         })
        infoModel.append({
                             "name": i18n("Tags:"),
                             "value": searchModel.get(
                                          searchTable.currentRow).tags
                         })
    }
    ColumnLayout {
        anchors.fill: parent
        Layout.alignment: Qt.AlignTop | Qt.AlignRight
        id: view
        RowLayout {
            id: searchRow
            Button {
                id: diaopen
                text: i18n("Search")
                iconName: "search"
                onClicked: {
                    searchDialog.open()
                }
                enabled: searchDialog.visible ? false : true
            }
            QQC2.Drawer {
                id: searchDialog
                height: diaopen.height
                background: Rectangle {
                    color: "transparent"
                    border.width: 0
                }
                interactive: true
                rightPadding: units.smallSpacing * 2
                position: 1
                visible: false
                edge: Qt.RightEdge
                y: searchRow.height + units.smallSpacing * 2
                Action {
                    id: acceptActionDialog
                    shortcut: "Return"
                    enabled: true
                    onTriggered: {
                        if (input.text !== "") {
                            var arr = ["name", "country", "language", "tag"]
                            var ind = by.currentIndex
                            var indarr = arr[ind]
                            testPlay.stop()
                            searchModel.clear()
                            configSearch.currentUrl = ""
                            getStations("by" + indarr, input.text)
                            searchDialog.close()
                        }
                    }
                }
                Action {
                    id: acceptActionDialog2
                    shortcut: "Enter"
                    enabled: true
                    onTriggered: {
                        if (input.text !== "") {
                            var arr = ["name", "country", "language", "tag"]
                            var ind = by.currentIndex
                            var indarr = arr[ind]
                            testPlay.stop()
                            searchModel.clear()
                            configSearch.currentUrl = ""
                            getStations("by" + indarr, input.text)
                            searchDialog.close()
                        }
                    }
                }
                RowLayout {
                    Label {
                        text: i18n("Search by")
                    }
                    ComboBox {
                        id: by
                        model: [i18n("name"), i18n("country"), i18n(
                                "language"), i18n("tags")]
                    }

                    QQC2.TextField {
                        id: input
                        Layout.fillWidth: true
                        placeholderText: i18n("Search")
                        PlasmaCore.IconItem {
                            source: "edit-clear"
                            visible: input.text.length > 0
                            height: parent.height
                            anchors.right: searchstart.left
                            anchors.rightMargin: units.smallSpacing
                            MouseArea {
                                cursorShape: Qt.PointingHandCursor
                                anchors.fill: parent
                                onClicked: {
                                    input.text = ""
                                    searchModel.clear()
                                    getStations()
                                    input.accepted()
                                    searchDialog.close()
                                }
                            }
                        }
                        PlasmaCore.IconItem {
                            id: searchstart
                            source: "search"
                            visible: input.text.length > 0
                            height: parent.height
                            anchors.right: parent.right
                            anchors.rightMargin: units.smallSpacing
                            MouseArea {
                                cursorShape: Qt.PointingHandCursor
                                anchors.fill: parent
                                onClicked: {
                                    if (input.text !== "") {
                                        var arr = ["name", "country", "language", "tag"]
                                        var ind = by.currentIndex
                                        var indarr = arr[ind]
                                        testPlay.stop()
                                        searchModel.clear()
                                        configSearch.currentUrl = ""
                                        getStations("by" + indarr, input.text)
                                        searchDialog.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        TableView {
            id: searchTable
            model: searchModel
            flickableItem.onContentYChanged: {
                if (flickableItem.contentY > flickableItem.contentHeight - searchTable.height * 2
                        && configSearch.stat == 1) {

                    configSearch.offset = configSearch.offset + 500
                    loadMore()
                }
            }
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            Layout.fillHeight: true
            Layout.fillWidth: true
            onCurrentRowChanged: {
                infoModel.clear()
                testtext.text = ""
                testPlay.stop()
                checkServer.stop()
                checkServer.source = ""
                checkServers()
            }

            BusyIndicator {
                id: busy
                running: false
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: true
            }
            Label {
                text: i18n("Get list of stations\nPlease wait...")
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.top: busy.bottom
                id: gettext
                visible: false
                enabled: true
            }

            TableViewColumn {
                role: "name"
                id: hei
                title: i18n("Name")
            }
        }
        TableView {
            id: infoTable
            Layout.fillHeight: true
            Layout.fillWidth: true
            model: infoModel
            BusyIndicator {
                id: busyinfo
                running: false
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: true
            }
            Label {
                text: i18n("Check server status\nPlease wait...")
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.top: busyinfo.bottom
                id: gettext2
                visible: false
                enabled: true
            }
            TableViewColumn {
                id: fircol
                role: "name"
                title: i18n(" ")
                delegate: Item {
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: styleData.textColor
                        elide: styleData.elideMode
                        text: styleData.value ? styleData.value : " "
                    }
                }
            }
            TableViewColumn {
                role: "value"
                title: i18n(" ")
                width: parent.width - fircol.width - 25
                delegate: Item {
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: styleData.row == 2 ? styleData.value == "Error" ? "red" : "green" : styleData.textColor
                        elide: styleData.elideMode
                        text: styleData.value ? styleData.value : i18n(
                                                    "Unknown")
                    }
                }
            }
        }

        RowLayout {
            Button {
                id: playButton
                enabled: false
                text: isPlaying() ? i18n("Stop") : i18n("Play")
                iconName: isPlaying(
                              ) ? "media-playback-stop" : "media-playback-start"
                onClicked: {
                    if (isPlaying()) {
                        testPlay.stop()
                        testPlay.source = ""
                    } else {
                        testPlay.stop()
                        testPlay.source = searchModel.get(
                                    searchTable.currentRow).url_resolved
                        testPlay.play()
                    }
                }
            }
            Button {
                id: addButton
                text: i18n("Add Station")
                iconName: "list-add"
                enabled: false
                onClicked: {
                    var itemObject = {
                        "name": searchModel.get(searchTable.currentRow).name,
                        "hostname": searchModel.get(
                                        searchTable.currentRow).url_resolved,
                        "active": true
                    }
                    serversModel.append(itemObject)
                    cfg_servers = JSON.stringify(getServersArray())
                    testtext.text = i18n(
                                "Station added. Click 'Apply' to save changes.")
                }
            }
        }
        Label {
            id: testtext
            text: ""
            color: "green"
        }
    }

    MediaPlayer {
        id: testPlay
    }
    MediaPlayer {
        id: checkServer
        volume: 0
        onError: {
            checkServer.source = ""
            searchModel.get(searchTable.currentRow).status = "Error"
            loadInfo()
            infoTable.enabled = true
            busyinfo.running = false
            gettext2.visible = false
            addButton.enabled = false
            playButton.enabled = false
        }
        onBufferProgressChanged: {
            checkServer.stop()
            checkServer.source = ""
            infoModel.clear()
            searchModel.get(searchTable.currentRow).status = "OK"
            loadInfo()
            infoTable.enabled = true
            busyinfo.running = false
            gettext2.visible = false
            addButton.enabled = true
            playButton.enabled = true
        }
        onPlaying: {
            infoTable.enabled = false
            busyinfo.running = true
            gettext2.visible = true
            addButton.enabled = false
            playButton.enabled = false
        }
    }
    function checkServers() {
        checkServer.stop()
        checkServer.source = ""
        checkServer.source = searchModel.get(
                    searchTable.currentRow).url_resolved
        checkServer.play()
    }

    function isPlaying() {
        return testPlay.playbackState == MediaPlayer.PlayingState
    }
    function getServersArray() {
        var serversArray = []

        for (var i = 0; i < serversModel.count; i++) {
            serversArray.push(serversModel.get(i))
        }

        return serversArray
    }
}
