import QtQuick 2.12
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.19 as Kirigami
import QtMultimedia 5.8
import ".."

ColumnLayout {
    id: configSearch
    ListModel {
        id: searchModel
        dynamicRoles: true
    }
    StationsModel {
        id: stationsModel
    }
    property var items: ["fr", "de", "nl"]
    property string server: ""
    property string cfg_servers: plasmoid.configuration.servers
    property int limit: 500
    property int offset: 0
    property string currentUrl
    property int stat: 1
    // property string cfg_version: plasmoid.configuration.version
    property bool isNoSearch: false
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
    function setHeaders(xmlhttp) {
        xmlhttp.setRequestHeader("User-Agent", "AdvancedRadio/2.0")
    }
    function getStations(by, val) {
        configSearch.isNoSearch = typeof (by) != "undefined"
                && by !== null ? false : true
        configSearch.offset = 0
        var item = configSearch.server
        busy.running = true
        busy.visible = true
        //  infoModel.clear()
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
                    var servers = JSON.parse(xmlhttp.responseText)
                    searchModel.clear()
                    for (var i = 0; i < servers.length; i++) {
                        searchModel.append(servers[i])
                        searchModel.setProperty(i, "name",
                                                servers[i].name.replace(
                                                    /\n/g, ' ').trim())
                        searchModel.setProperty(i, "added", false)
                    }
                    busy.running = false
                    busy.visible = false
                    gettext.visible = servers.length > 0 ? false : true
                    gettext.text = servers.length
                            === 0 ? i18n("Nothing found\nTry changing your query") : i18n(
                                        "Get list of stations\nPlease wait...")
                    view.enabled = true
                    if (servers.length === 0) {

                    }
                    configSearch.stat = 1
                }
            }
        }
        xmlhttp.send()
    }
    function loadMore() {
        configSearch.stat = 0
        var xmlhttp = new XMLHttpRequest
        var url = configSearch.currentUrl.split(
                    "?")[0] + "?hidebroken=true&limit=" + configSearch.limit
                + "&offset=" + configSearch.offset
        xmlhttp.open("GET", url)
        setHeaders(xmlhttp)
        xmlhttp.onreadystatechange = function () {
            if (xmlhttp.readyState == xmlhttp.DONE) {
                if (xmlhttp.status == 200) {
                    configSearch.currentUrl = url
                    var servers = JSON.parse(xmlhttp.responseText)
                    if (servers.length > 0) {
                        for (var i = 0; i < servers.length; i++) {
                            searchModel.append(servers[i])
                            searchModel.setProperty(i, "name",
                                                    servers[i].name.replace(
                                                        /\n/g, ' ').trim())
                            searchModel.setProperty(i, "added", false)
                        }
                        configSearch.stat = 1
                    }
                }
            }
        }
        xmlhttp.send()
    }

    Component.onCompleted: {
        stationsModel.clear()
        var servers = JSON.parse(cfg_servers)
        for (var i = 0; i < servers.length; i++) {
            stationsModel.append(servers[i])
        }
        configSearch.stat = 0
        getServer()
        getStations()
    }
    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        id: view
        Kirigami.Dialog {
            id: searchDrawer
            title: i18n("Search Station")
            padding: Kirigami.Units.largeSpacing
            standardButtons: Kirigami.Dialog.NoButton
            RowLayout {
                Controls.Label {
                    text: i18n("Search by")
                }
                Controls.ComboBox {
                    id: by
                    model: [i18n("name"), i18n("country"), i18n(
                            "language"), i18n("tags")]
                }
                Kirigami.SearchField {
                    id: search
                    Layout.fillWidth: true
                    autoAccept: false
                    onAccepted: {
                        if (text !== "") {
                            var arr = ["name", "country", "language", "tag"]
                            var ind = by.currentIndex
                            var indarr = arr[ind]
                            testPlay.stop()
                            searchModel.clear()
                            configSearch.currentUrl = ""
                            getStations("by" + indarr, text)
                            searchDrawer.close()
                        } else {
                            if (!configSearch.isNoSearch) {
                                searchModel.clear()
                                getStations()
                                searchDrawer.close()
                            }
                        }
                    }
                }
                Controls.Button {
                    icon.name: "search"
                    enabled: search.text != ""
                    onClicked: {
                        search.accepted()
                    }
                }
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
                clip: true
                contentItem: RowLayout {
                    id: trackRow
                    clip: true
                    Kirigami.Icon {
                        z: 2
                        clip: true
                        source: model
                                && model.favicon ? model.favicon : "audio-x-generic"
                        placeholder: "audio-x-generic"
                        fallback: "audio-x-generic"
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
                            text: model ? model.name.trim().replace(/\n/g,
                                                                    " ") : ""
                            anchors.verticalCenter: parent.verticalCenter
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
                    Kirigami.Chip {
                        Layout.rightMargin: bitrate.visible ? 0 : Kirigami.Units.largeSpacing
                        text: model && model.codec ? model.codec : ""
                        closable: false
                        enabled: false
                        visible: model && model.codec !== "UNKNOWN"
                        implicitWidth: implicitContentWidth
                    }
                    Kirigami.Chip {
                        id: bitrate
                        Layout.rightMargin: Kirigami.Units.largeSpacing
                        text: model && model.bitrate ? model.bitrate + i18n(
                                                           "kBit/s") : ""
                        closable: false
                        enabled: false
                        visible: model && model.bitrate !== 0
                        implicitWidth: implicitContentWidth
                    }
                }
                actions: [
                    Kirigami.Action {
                        id: info
                        iconName: "documentinfo"
                        text: i18n("Info")
                        onTriggered: {
                            mainList.currentIndex = model.index
                            if (testPlay.source != searchModel.get(
                                    mainList.currentIndex).url_resolved) {
                                testPlay.stop()
                            }
                            message.visible = false
                            infoSheet.open()
                        }
                    },
                    Kirigami.Action {
                        id: addButton
                        text: i18n("Add Station")
                        icon.name: model ? model.added ? "checkbox" : "list-add" : ""
                        enabled: model && !model.added
                        onTriggered: {
                            mainList.currentIndex = model.index
                            if (testPlay.source != searchModel.get(
                                    mainList.currentIndex).url_resolved) {
                                testPlay.stop()
                            }
                            searchModel.setProperty(model.index, "added", true)
                            var itemObject = {
                                "name": searchModel.get(
                                            mainList.currentIndex).name,
                                "hostname": searchModel.get(
                                                mainList.currentIndex).url_resolved,
                                "active": true
                            }
                            stationsModel.append(itemObject)
                            cfg_servers = JSON.stringify(getServersArray())
                            if (message.visible == false) {
                                message.positive = true
                                message.text = i18n(
                                    "Station is added. Click 'Apply' to save changes.")
                                message.visible = true
                                closetimer.restart()
                            }
                        }
                    },
                    Kirigami.Action {
                        id: playButton
                        text: model ? isPlaying() && mainList.currentIndex
                                      == model.index ? i18n("Stop") : i18n(
                                                           "Play") : ""
                        icon.name: model ? isPlaying()
                                           && mainList.currentIndex == model.index ? "media-playback-stop" : "media-playback-start" : ""
                        enabled: mainList.currentIndex != -1 && searchModel.get(
                                     mainList.currentIndex).lastcheckok
                                 && searchModel.get(
                                     mainList.currentIndex).lastcheckok == 1
                        onTriggered: {
                            mainList.currentIndex = model.index
                            message.visible = false
                            if (isPlaying()
                                && testPlay.source == searchModel.get(
                                    mainList.currentIndex).url_resolved) {
                                testPlay.stop()
                                testPlay.source = ""
                            } else {
                                testPlay.stop()
                                testPlay.source = searchModel.get(
                                    mainList.currentIndex).url_resolved
                                testPlay.play()
                            }
                        }
                    }
                ]
            }
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
            Controls.BusyIndicator {
                id: busy
                running: false
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: true
                implicitWidth: Kirigami.Units.iconSizes.enormous
                implicitHeight: width
            }
            Controls.Label {
                text: i18n("Get list of stations\nPlease wait...")
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.top: busy.bottom
                id: gettext
                visible: false
                enabled: true
            }
            model: searchModel
            moveDisplaced: Transition {
                YAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
            onContentYChanged: {
                if (contentY > contentHeight - height * 2
                        && configSearch.stat == 1) {
                    configSearch.offset = configSearch.offset + 500
                    loadMore()
                }
            }
            delegate: Kirigami.DelegateRecycler {
                width: parent ? parent.width - scrollBar.width : implicitWidth
                sourceComponent: delegateComponent
            }
        }
        Kirigami.InlineMessage {
            property bool positive
            id: message
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
                message.visible = false
            }
        }
        RowLayout {
            Controls.Button {
                text: i18n("Search") + "..."
                icon.name: "search"
                onClicked: searchDrawer.open()
            }
            Item {
                Layout.fillWidth: true
            }
            Controls.Button {
                text: i18n("Clear Results")
                icon.name: "edit-clear-all"
                enabled: search.text != ""
                onClicked: {
                    searchModel.clear()
                    search.text = ""
                    search.accepted()
                }
            }
        }
        Kirigami.OverlaySheet {
            id: infoSheet
            header: Kirigami.Heading {
                text: i18n("Station Info")
            }
            contentItem: Kirigami.FormLayout {
                id: formLayout
                wideMode: true
                Kirigami.Heading {
                    text: mainList.currentIndex != -1 ? searchModel.get(
                                                            mainList.currentIndex).name : ""
                    Kirigami.FormData.label: i18n("Name:")
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    Layout.maximumWidth: configSearch.width - Kirigami.Units.smallSpacing
                    Layout.preferredWidth: configSearch.width - Kirigami.Units.smallSpacing
                }
                Kirigami.Icon {
                    source: mainList.currentIndex != -1 && searchModel.get(
                                mainList.currentIndex).favicon
                            != "" ? searchModel.get(
                                        mainList.currentIndex).favicon : "audio-x-generic"
                    placeholder: "audio-x-generic"
                    fallback: "audio-x-generic"
                    implicitWidth: Kirigami.Units.iconSizes.huge
                    implicitHeight: Kirigami.Units.iconSizes.huge
                    Kirigami.FormData.label: i18n("Favicon:")
                }
                Kirigami.UrlButton {
                    url: mainList.currentIndex != -1 ? searchModel.get(
                                                           mainList.currentIndex).homepage : ""
                    Kirigami.FormData.label: i18n("Homepage:")
                    wrapMode: Text.WrapAnywhere
                    Layout.maximumWidth: configSearch.width
                    horizontalAlignment: Text.AlignLeft
                }

                Kirigami.UrlButton {
                    url: mainList.currentIndex != -1 ? searchModel.get(
                                                           mainList.currentIndex).url_resolved : ""
                    Kirigami.FormData.label: i18n("Stream URL:")
                    wrapMode: Text.WrapAnywhere
                    Layout.maximumWidth: configSearch.width
                    horizontalAlignment: Text.AlignLeft
                }
                Controls.Label {
                    property string status: mainList.currentIndex
                                            != -1 ? searchModel.get(
                                                        mainList.currentIndex).lastcheckok
                                                    == 1 ? i18n("OK") : i18n(
                                                               "Error") : ""
                    Kirigami.FormData.label: i18n("Server status:")
                    Layout.maximumWidth: configSearch.width
                    text: mainList.currentIndex
                          != -1 ? status + " (" + i18n("last check: ")
                                  + Date.fromLocaleString(locale,
                                                          searchModel.get(mainList.currentIndex).lastchecktime, "yyyy-MM-dd hh:mm:ss").toLocaleString(Qt.locale(), Locale.ShortFormat) + ")" : ""
                    color: mainList.currentIndex != -1 ? searchModel.get(
                                                             mainList.currentIndex).lastcheckok == 1 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                }
                Kirigami.Chip {
                    Kirigami.FormData.label: i18n("Codec:")
                    text: mainList.currentIndex != -1 ? searchModel.get(
                                                            mainList.currentIndex).codec : ""
                    closable: false
                    enabled: false
                    visible: mainList.currentIndex != -1 && searchModel.get(
                                 mainList.currentIndex).codec != "UNKNOWN"
                }
                Kirigami.Chip {
                    Kirigami.FormData.label: i18n("Bitrate:")
                    text: mainList.currentIndex != -1 ? searchModel.get(
                                                            mainList.currentIndex).bitrate.toString(
                                                            ) + i18n(
                                                            "kBit/s") : ""
                    closable: false
                    enabled: false
                    visible: mainList.currentIndex != -1 && searchModel.get(
                                 mainList.currentIndex).bitrate != 0
                }
                Controls.Label {
                    Kirigami.FormData.label: i18n("Country:")
                    text: mainList.currentIndex != -1 ? searchModel.get(
                                                            mainList.currentIndex).country : ""
                    visible: text != ""
                }
                Controls.Label {
                    Kirigami.FormData.label: i18n("Language:")
                    text: mainList.currentIndex != -1 ? searchModel.get(
                                                            mainList.currentIndex).language : ""
                    visible: mainList.currentIndex != -1 && searchModel.get(
                                 mainList.currentIndex).language != ""
                }

                Flow {
                    Kirigami.FormData.label: i18n("Tags:")
                    Layout.maximumWidth: configSearch.width
                    Layout.preferredWidth: configSearch.width
                    spacing: Kirigami.Units.smallSpacing
                    visible: mainList.currentIndex != -1 && searchModel.get(
                                 mainList.currentIndex).tags.length > 0
                    Repeater {
                        id: tagsRepeater
                        property var arr: mainList.currentIndex
                                          != -1 ? searchModel.get(
                                                      mainList.currentIndex).tags.split(
                                                      ",") : []

                        model: arr
                        delegate: Kirigami.Chip {
                            closable: false
                            enabled: false
                            text: modelData
                        }
                    }
                }
            }
        }
    }
    MediaPlayer {
        id: testPlay
        onError: {
            message.positive = false
            message.text = i18n("Error") + ": " + testPlay.errorString
            message.visible = true
            closetimer.restart()
        }
    }
    function checkServers() {
        checkServer.stop()
        checkServer.source = ""
        checkServer.source = searchModel.get(mainList.currentIndex).url_resolved
        checkServer.play()
    }
    function isPlaying() {
        return testPlay.playbackState == MediaPlayer.PlayingState
    }
    function getServersArray() {
        var serversArray = []
        for (var i = 0; i < stationsModel.count; i++) {
            serversArray.push(stationsModel.get(i))
        }
        return serversArray
    }
}
