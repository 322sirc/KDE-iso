
/***************************************************************************
*   Copyright (C) 2019 by Dr_i-glu4IT <dr@i-glu4it.ru>     *
***************************************************************************/
import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtMultimedia 5.8
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.2

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    anchors.centerIn: parent

    width: 220 * units.devicePixelRatio
    height: 300 * units.devicePixelRatio
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

    PlasmaCore.DataSource {
        id: imageget
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
        target: imageget
        onExited: {
            root.imglocal = root.imgurl.startsWith(
                        "http") ? "file:///tmp/arp_image" : Qt.resolvedUrl(
                                      "../images/unknown.svg")
            root.notification == true ? title != i18n("Advanced Radio Player")
                                        && title != i18n(
                                            "Unknown Artist") ? createNotification(
                                                                    ) : '' : ''
        }
    }
    Component.onCompleted: {
        playMusic.stop()
        playMusic.source = ''
        reloadServerModel()
    }

    Connections {
        target: plasmoid.configuration
        onServersChanged: {
            playMusic.stop()
            playMusic.source = ''
            reloadServerModel()
        }
    }

    Item {
        id: tool

        property int preferredTextWidth: units.gridUnit * 20
        Layout.minimumWidth: childrenRect.width + units.gridUnit
        Layout.minimumHeight: childrenRect.height + units.gridUnit
        Layout.maximumWidth: childrenRect.width + units.gridUnit
        Layout.maximumHeight: childrenRect.height + units.gridUnit

        RowLayout {

            anchors {
                left: parent.left
                top: parent.top
                margins: units.gridUnit / 2
            }

            spacing: units.largeSpacing
            Image {
                id: tooltipImage
                source: root.imgurl
                visible: tool != null && tool.image != ""
                Layout.alignment: Qt.AlignTop
                width: 64
                ColorOverlay {
                    anchors.fill: tooltipImage
                    source: tooltipImage
                    color: PlasmaCore.ColorScope.textColor
                    visible: !root.imgurl.startsWith("http")
                    antialiasing: true
                }
            }

            ColumnLayout {
                PlasmaExtras.Heading {
                    id: tooltipMaintext
                    level: 3
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    text:
                        /*root.title == i18n("Unknown Artist")
                          && plasmoid.configuration.showStation ? root.stationName :*/ root.title
                    visible: text != ""
                }
                RowLayout {
                    PlasmaComponents.Label {
                        id: tooltipSubtext
                        Layout.fillWidth: true
                        height: undefined
                        wrapMode: Text.WordWrap
                        text:
                            /*root.subtitle == i18n("Unknown Song")
                              && plasmoid.configuration.showStation ? "" :*/ root.subtitle
                        opacity: 0.8
                        visible: text != ""
                        maximumLineCount: 8
                    }
                    PlasmaComponents.ToolButton {
                        id: lyrics
                        iconName: "view-media-lyrics"
                        visible: root.title !== i18n("Unknown Artist")
                                 && root.title !== i18n("Advanced Radio Player")
                        onClicked: {
                            getLyrics()
                        }
                    }
                }
            }
        }
    }

    Window {
        id: info
        visible: false
        minimumWidth: 300 * units.devicePixelRatio
        minimumHeight: 300 * units.devicePixelRatio
        title: i18n("Song Info")
        color: PlasmaCore.ColorScope.backgroundColor
        onWidthChanged: {

        }

        Component.onCompleted: {
            setX(Screen.width / 2 - width / 2)
            setY(Screen.height / 2 - height / 2)
        }

        Item {
            id: page
            anchors.fill: parent
            anchors.margins: units.gridUnit / 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.imgurl != "../images/blank.svg" && root.title != i18n(
                         "Advanced Radio Player")

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: units.gridUnit

                Image {
                    source: root.imgurl
                    width: 64 * units.devicePixelRatio
                    height: 64 * units.devicePixelRatio
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 64
                    sourceSize.height: 64
                }
                GridLayout {
                    columns: 2
                    id: t
                    rowSpacing: 0
                    Layout.fillWidth: true

                    PlasmaComponents.Label {
                        id: art
                        text: i18n("Artist") + " - " + root.title
                        Layout.fillWidth: true
                        onTextChanged: {
                            fixwidth()
                        }
                    }
                    PlasmaComponents.ToolButton {
                        id: urlart
                        Layout.fillWidth: false
                        iconName: "globe"
                        enabled: root.urltitle != ""
                        onClicked: Qt.openUrlExternally(root.urltitle)
                    }
                    PlasmaComponents.Label {
                        id: track
                        text: i18n("Song") + " - " + root.subtitle
                        Layout.fillWidth: true
                        onTextChanged: {
                            fixwidth()
                        }
                    }
                    PlasmaComponents.ToolButton {
                        iconName: "globe"
                        enabled: root.urlsubtitle != ""
                        onClicked: Qt.openUrlExternally(root.urlsubtitle)
                    }
                    PlasmaComponents.Label {
                        id: alb
                        Layout.fillWidth: true
                        text: root.album != "" ? i18n("Album") + " - " + root.album : i18n(
                                                     "Album") + " - " + i18n(
                                                     "Unknown")
                        onTextChanged: {
                            fixwidth()
                        }
                    }
                    PlasmaComponents.ToolButton {
                        iconName: "globe"
                        enabled: root.urlalbum != ""
                        onClicked: Qt.openUrlExternally(root.urlalbum)
                    }
                }
            }
            PlasmaComponents.TextArea {
                id: desc
                width: parent.width
                height: parent.height - t.height - units.gridUnit / 2
                anchors.bottom: parent.bottom
                readOnly: true
                text: root.songinfo
                wrapMode: Text.WordWrap
                visible: root.imgurl != "../images/blank.svg"
                enabled: root.songinfo != ""
                PlasmaComponents.Label {
                    text: i18n("No information for this song")
                    anchors.centerIn: parent
                    visible: isPlaying() && desc.text.trim() == ""
                }
            }
        }
        PlasmaComponents.Label {
            id: turnon
            text: i18n("Please turn on radio")
            visible: !root.trytoplay
            anchors.centerIn: parent
        }
        BusyIndicator {
            id: infobusy
            visible: !page.visible && !turnon.visible
            anchors.centerIn: parent
        }
    }

    property bool notification: plasmoid.configuration.Notification
    property bool transback: plasmoid.configuration.transback
    property string fullTitle: ""
    property string title: i18n("Advanced Radio Player")
    property string subtitle: i18n("Choose station")
    property string imgurl: isPlaying(
                                ) ? "../images/unknown.svg" : "../images/blank.svg"
    property color textColor: plasmoid.location == PlasmaCore.Types.Floating
                              && plasmoid.configuration.transback ? plasmoid.configuration.fontColor : PlasmaCore.ColorScope.textColor
    property string imglocal
    property string songinfo: ""
    property string album: ""
    property string urltitle: ""
    property string urlsubtitle: ""
    property string urlalbum: ""
    property bool trytoplay: false
    property int lastplay: 0
    property string stationName: ""
    onSubtitleChanged: {
        root.fullTitle = isPlaying() ? playMusic.metaData.title : ""
    }

    onImgurlChanged: {

        root.notification == true ? title != i18n("Advanced Radio Player")
                                    && title != i18n(
                                        "Unknown Artist") ? getimage() : "" : ""
        im.restart()
    }

    Plasmoid.backgroundHints: plasmoid.configuration.transback ? "NoBackground" : "DefaultBackground"

    MediaPlayer {
        id: playMusic
        onError: {
            playMusic.stop()
            reloadServerModel()
        }
        onStopped: {
            playMusic.bufferProgress == 0
            playMusic.stop()
            playMusic.source = ""

            root.title = i18n("Advanced Radio Player")
            root.stationName = i18n("Advanced Radio Player")
        }
        volume: 0.8
    }

    Timer {
        interval: 1000
        repeat: isPlaying() ? true : false
        running: false
        id: im
        onTriggered: {
            if (playMusic.metaData.title != undefined
                    && playMusic.metaData.title.indexOf(' - ') != -1
                    && playMusic.metaData.title.length < 1000
                    && playMusic.metaData.title != root.fullTitle) {

                var strings = playMusic.metaData.title.split(' - ')
                var var1 = strings[0].trim(), var2 = strings[1].trim()
                root.fullTitle = playMusic.metaData.title
                var xmlhttp = new XMLHttpRequest()
                var url = "http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key=ada39a6834a3be4d641cc1aec7e64d48&artist=" + encodeURIComponent(
                            var1) + "&track=" + encodeURIComponent(
                            var2) + "&autocorrect=1&format=json"
                xmlhttp.onreadystatechange = function () {
                    if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                        var myArr = JSON.parse(xmlhttp.responseText)

                        myFunction(myArr)
                    }
                }
                xmlhttp.open("GET", url)
                xmlhttp.send()
                function myFunction(arr) {
                    var art = (arr.track
                               && arr.track.artist) ? (arr.track.artist.name) : var1
                    var tit = (arr.track) ? (arr.track.name) : var2
                    var img
                    root.title = (isPlaying()) ? art : i18n(
                                                     "Advanced Radio Player")
                    root.urltitle = (arr.track
                                     && arr.track.artist) ? (arr.track.artist.url) : ""
                    root.subtitle = (isPlaying()) ? tit : i18n("Choose station")
                    if (arr.track && arr.track.album
                            && arr.track.album.image[1]['#text']
                            && arr.track.album.image[1]['#text'] != 'undefined'
                            && arr.track.album.image[1]['#text'].startsWith(
                                'http')) {

                        img = arr.track.album.image[1]['#text']
                    } else {
                        img = "../images/unknown.svg"
                    }
                    root.urlsubtitle = (arr.track && arr.track.url
                                        && arr.track.url != "") ? arr.track.url : ""
                    root.urlalbum = (arr.track.album && arr.track.album.url
                                     && arr.track.album.url != "") ? arr.track.album.url : ""

                    root.imgurl = (isPlaying()) ? img : "../images/blank.svg"
                    if (isPlaying()) {
                        im.restart()
                    }
                    if (arr.track && arr.track.wiki && arr.track.wiki.content
                            && arr.track.wiki.content != "") {
                        root.songinfo = arr.track.wiki.content.split(
                                    '<a href="http://www.last.fm/music/')[0]
                    } else {
                        root.songinfo = ""
                    }

                    if (arr.track && arr.track.album && arr.track.album.title
                            && arr.track.album.title != "") {
                        root.album = arr.track.album.title
                    } else {
                        root.album = ""
                    }
                }
            } else {

                if (playMusic.metaData.title != root.fullTitle) {
                    root.imgurl = (isPlaying()
                                   && root.imglocal == "file:///tmp/arp_image") ? "../images/unknown.svg" : "../images/blank.svg"
                    root.title = (isPlaying()) ? i18n("Unknown Artist") : i18n(
                                                     "Advanced Radio Player")
                    root.subtitle = (isPlaying()) ? i18n("Unknown Song") : i18n(
                                                        "Choose station")
                    root.album = ""
                    root.urlalbum = ""
                    root.urlsubtitle = ""
                    root.urltitle = ""
                    root.songinfo = ""

                    im.restart()
                }
            }
        }
    }

    function getimage() {
        imageget.exec("wget -O /tmp/arp_image " + root.imgurl)
    }

    function createNotification() {
        executable.exec(
                    'gdbus call --session             --dest org.freedesktop.Notifications             --object-path /org/freedesktop/Notifications             --method org.freedesktop.Notifications.Notify             "Advanced Radio Player"             0             "'
                    + root.imglocal + '"             "' + root.title + '"             "'
                    + root.subtitle + '"             []             {}             5000')
    }
    function getLyrics() {
        info.visible = info.visible ? false : true
    }

    Plasmoid.compactRepresentation: Item {
        id: comp
        Layout.preferredWidth: !plasmoid.configuration.panel ? "" : plasmoid.configuration.panel
                                                               && plasmoid.configuration.minimize
                                                               && root.trytoplay ? plasmoid.configuration.panelWidth : plasmoid.configuration.panel && plasmoid.configuration.minimize && !trytoplay ? "" : plasmoid.configuration.panelWidth
        height: parent.height
        clip: true

        PlasmaCore.IconItem {
            id: ima
            anchors.fill: parent
            visible: !plasmoid.configuration.panel
                     || !plasmoid.configuration.minimize
            source: plasmoid.configuration.icon
            width: parent.width
            height: parent.height
            opacity: root.trytoplay ? 0.5 : 1
        }

        PlasmaCore.IconItem {
            id: stat
            source: 'media-playback-start'
            visible: isPlaying() && !plasmoid.configuration.panel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height * 0.5
        }
        BusyIndicator {
            visible: trytoplay && !isPlaying()
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height * 0.5
            width: parent.width * 0.5
        }

        QQC2.Label {
            id: volumeControl
            visible: false
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            Layout.fillWidth: true
            width: parent.width
            height: parent.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.Fit
            minimumPointSize: 5
            font.pointSize: nameText25.font.pointSize
            text: plasmoid.configuration.panel
                  && !plasmoid.configuration.minimize
                  || plasmoid.configuration.panel && isPlaying(
                      ) ? Math.round(playMusic.volume * 100) + "% " + i18n(
                              "Volume") : Math.round(
                              playMusic.volume * 100) + "%"
        }

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: parent ? units.smallSpacing : 0
            anchors.bottomMargin: parent ? units.smallSpacing : 0
            radius: parent ? units.smallSpacing : 0
            visible: plasmoid.configuration.panel
                     && !plasmoid.configuration.minimize
                     || plasmoid.configuration.panel
                     && plasmoid.configuration.minimize && isPlaying()
            border.width: plasmoid.configuration.border
                          && plasmoid.configuration.panel
                          && !plasmoid.configuration.minimize
                          || plasmoid.configuration.border
                          && plasmoid.configuration.panel
                          && plasmoid.configuration.minimize && isPlaying(
                              ) ? 0.6 : 0
            border.color: PlasmaCore.ColorScope.textColor
            id: square
            width: plasmoid.configuration.panel && isPlaying(
                       ) ? plasmoid.configuration.panelWidth : 0
            height: parent.height
            onWidthChanged: {
                anim.restart()
                volumeControl.visible = false
                stat.opacity = 1
                ima.visible = !plasmoid.configuration.panel
                        || plasmoid.configuration.panel
                        && plasmoid.configuration.minimize && !trytoplay
                nameText25.visible = plasmoid.configuration.panel ? true : false
                im.start()
            }
            color: "transparent"
            PlasmaComponents.Label {
                Layout.fillWidth: true
                id: nameText25
                color: textColor
                opacity: 1
                height: parent.height

                text:
                    /*root.title == i18n("Unknown Artist")
                      && plasmoid.configuration.showStation ? root.stationName : */ isPlaying() ? root.title + ' - ' + root.subtitle : i18n("Advanced Radio Player")
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter

                onTextChanged: {

                    im.restart()
                    anim.restart()
                }
            }
            NumberAnimation {
                property: "x"
                id: anim
                target: nameText25
                from: isPlaying() && root.title != i18n(
                          "Advanced Radio Player") ? plasmoid.configuration.panelWidth : plasmoid.configuration.panelWidth + square.width / 2
                to: (isPlaying()) ? -nameText25.width : -nameText25.width / 2
                                    + plasmoid.configuration.panelWidth / 2
                duration: 20 * Math.abs(to - from)

                loops: (isPlaying() && root.title != i18n(
                            "Advanced Radio Player")) ? Animation.Infinite : 1
            }
        }

        Timer {
            id: elapsedTimer
            interval: 3000
            running: false
            repeat: false
            onTriggered: {
                volumeControl.visible = false
                stat.opacity = 1
                ima.visible = plasmoid.configuration.panel
                        && !plasmoid.configuration.minimize
                        || plasmoid.configuration.panel
                        && root.trytoplay ? false : true
                nameText25.visible = plasmoid.configuration.panel ? true : false
                im.start()
            }
        }

        MouseArea {
            id: mouseArea
            width: parent.width
            height: parent.width
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onEntered: {

            }
            onExited: {
                elapsedTimer.start()
            }
            onClicked: {
                if (mouse.button == Qt.MiddleButton) {
                    refreshServer(root.lastplay)
                } else {
                    plasmoid.expanded = !plasmoid.expanded
                }
            }
            onWheel: {
                im.stop()
                volumeControl.visible = true
                stat.opacity = 0
                ima.visible = false
                nameText25.visible = false
                if (wheel.angleDelta.y > 0 && playMusic.volume < 1) {
                    playMusic.volume += 0.05
                } else if (wheel.angleDelta.y < 0 && playMusic.volume > 0) {
                    playMusic.volume -= 0.05
                }
                elapsedTimer.start()
            }
        }

        PlasmaCore.ToolTipArea {
            id: toolTip
            width: parent.width
            height: parent.height
            anchors.fill: parent
            mainItem: tool
            interactive: true
        }
    }

    Plasmoid.fullRepresentation: Rectangle {
        Layout.preferredWidth: 200 * units.devicePixelRatio
        Layout.preferredHeight: 300 * units.devicePixelRatio
        clip: true
        color: "transparent"
        anchors.margins: plasmoid.location == PlasmaCore.Types.Floating
                         && root.transback == true ? units.smallSpacing * 2 : 0
        Rectangle {
            id: squaref
            width: 200 * units.devicePixelRatio
            height: plasmoid.configuration.panel ? 0 : 20 * units.devicePixelRatio
            visible: !plasmoid.configuration.panel
            color: "transparent"
            PlasmaComponents.Label {
                id: nameText21
                color: textColor
                height: parent.height
                text: isPlaying() ?
                          /*root.title == i18n("Unknown Artist")
                              && plasmoid.configuration.showStation
                                ? root.stationName : */ root.title + ' - ' + root.subtitle : i18n(
                              "Advanced Radio Player")
                verticalAlignment: Text.AlignVCenter

                onTextChanged: {
                    im.restart()
                    anim2.restart()
                    console.log(root.title)
                }
            }
            NumberAnimation {
                property: "x"
                id: anim2
                target: nameText21
                from: isPlaying() && root.title != i18n("Advanced Radio Player")
                      && root.fullTitle
                      == playMusic.metaData.title ? squaref.width : squaref.width + 150
                to: (isPlaying(
                         )) ? -nameText21.width : -nameText21.width / 2 + squaref.width / 2
                duration: 20 * Math.abs(to - from)
                loops: (isPlaying() && root.title != i18n(
                            "Advanced Radio Player")) ? Animation.Infinite : 1
            }
            PlasmaCore.ToolTipArea {
                id: toolTip2
                width: parent.width
                height: parent.height
                anchors.fill: parent
                mainItem: tool
                interactive: true
                visible: plasmoid.location == PlasmaCore.Types.Floating
            }
            MouseArea {
                id: mouseArea2
                width: parent.width
                height: parent.width
                anchors.fill: parent
                hoverEnabled: true
                visible: plasmoid.location !== PlasmaCore.Types.Floating
                onEntered: {
                    (isPlaying()) ? anim2.pause() : anim2.resume()
                }
                onExited: {
                    anim2.resume()
                }
                onClicked: {

                }
            }
        }
        ListView {
            id: serversListView
            anchors.fill: parent
            anchors.topMargin: plasmoid.configuration.panel ? 0 : 25
            anchors.bottomMargin: 25
            model: serversModel
            clip: true

            spacing: 0
            delegate: Rectangle {
                height: nameText.paintedHeight ? nameText.paintedHeight + units.smallSpacing : 0
                color: model.status == 1 && isPlaying(
                           ) ? mouseArea3.containsMouse ? PlasmaCore.ColorScope.highlightColor : PlasmaCore.ColorScope.highlightColor : "transparent"
                border.color: mouseArea3.containsMouse || trytoplay
                              && model.status
                              == 1 ? PlasmaCore.ColorScope.highlightColor : "transparent"
                radius: nameText ? units.smallSpacing : 0

                width: parent.width

                PlasmaComponents.Label {
                    id: icon
                    color: model.status == 1 && isPlaying(
                               ) ? PlasmaCore.ColorScope.highlightedTextColor : textColor
                    height: parent.height
                    text: model.index + 1
                    width: 16 * units.devicePixelRatio
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    anchors.leftMargin: units.smallSpacing
                    anchors.left: parent.left

                    visible: mouseArea3.containsMouse
                             || model.status == 1 ? false : true
                }
                PlasmaCore.IconItem {
                    id: numberPlay
                    width: 16 * units.devicePixelRatio
                    anchors.leftMargin: units.smallSpacing
                    anchors.left: parent.left
                    height: parent.height

                    source: model.status == 1
                            && mouseArea3.containsMouse ? model.status == 1
                                                          && !mouseArea3.containsMouse ? isPlaying() && !mouseArea3.containsMouse ? 'media-playback-start' : 'media-playback-stop' : 'media-playback-stop' : 'media-playback-start'
                    visible: mouseArea3.containsMouse
                             || model.status == 1 ? true : false
                    opacity: model.status === 1
                             && playMusic.bufferProgress < 1 ? 0.3 : 1
                    colorGroup: model.status == 1 ? PlasmaCore.Theme.ComplementaryColorGroup : PlasmaCore.Theme.NormalColorGroup
                }
                BusyIndicator {
                    width: icon.width * 1
                    height: icon.height * 1
                    anchors.verticalCenter: icon.verticalCenter
                    anchors.horizontalCenter: icon.horizontalCenter
                    running: model.status === 1 && playMusic.bufferProgress < 1
                    visible: model.status === 1 && playMusic.bufferProgress < 1
                }
                PlasmaComponents.Label {
                    id: nameText

                    color: model.status == 1 && isPlaying(
                               ) ? PlasmaCore.ColorScope.highlightedTextColor : textColor
                    anchors.left: icon.right
                    anchors.leftMargin: units.smallSpacing
                    height: parent.height
                    text: model.name.length === 0 ? model.hostname : model.name
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font.bold: model.status === 1 ? true : false
                }

                MouseArea {
                    id: mouseArea3
                    anchors.top: icon.top
                    anchors.bottom: icon.bottom
                    anchors.left: icon.left
                    anchors.right: lyr.visible ? lyr.left : parent.right
                    width: serversListView.width
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {

                    }

                    onClicked: {
                        serversListView.currentIndex = model.index
                        root.lastplay = model.index
                        refreshServer(model.index)
                        //                        root.stationName = serversModel.get(
                        //                                    serversListView.currentIndex).name
                    }
                }
                PlasmaCore.IconItem {
                    id: lyr
                    source: "view-media-lyrics"
                    anchors.right: parent.right
                    height: parent.height
                    width: parent.height
                    visible: model.status === 1 && isPlaying()
                             && root.title != i18n("Unknown Artist")
                             && root.title != i18n("Advanced Radio Player")
                    colorGroup: PlasmaCore.Theme.ComplementaryColorGroup

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            getLyrics()
                        }
                    }
                }
            }
        }
        Rectangle {
            id: square2
            width: 200
            height: 30
            anchors.top: serversListView.bottom
            color: "transparent"
            z: 10
            PlasmaComponents.Label {
                id: nameText3
                color: textColor
                font.pixelSize: 10
                height: parent.height
                width: parent.width
                text: isPlaying(
                          ) ? i18n("Bitrate:") + ' ' + Math.round(
                                  playMusic.metaData.audioBitRate / 1000) + 'Kb/s, ' + i18n(
                                  "Genre:") + ' '
                              + playMusic.metaData.genre : playMusic.bufferProgress < 1
                              && play.running == true ? i18n("Buffering") + ' ' + Math.round(playMusic.bufferProgress * 100) + "%" : i18n(
                                                            "Choose station and enjoy...")
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        PlasmaComponents.Button {
            anchors.centerIn: parent
            text: i18n("Add stations")
            visible: serversModel.count == 0
            onClicked: plasmoid.action("configure").trigger()
        }
    }
    function reloadServerModel() {
        serversModel.clear()
        playMusic.stop()
        var servers = JSON.parse(plasmoid.configuration.servers)
        for (var i = 0; i < servers.length; i++) {
            if (servers[i].active) {
                serversModel.append(servers[i])
            }
        }
    }
    function refreshServer(index) {
        if (isPlaying() && playMusic.source == serversModel.get(
                    index).hostname) {
            root.trytoplay = false
            playMusic.stop()
            playMusic.source = ''
            serversModel.setProperty(index, "status", 0)
        } else {
            root.trytoplay = true
            playMusic.stop()
            playMusic.source = ''
            for (var i = 0; i < serversModel.count; i++) {
                serversModel.setProperty(i, "status", 0)
            }
            playMusic.source = serversModel.get(index).hostname
            serversModel.setProperty(index, "status", 1)
            play.start()
        }
    }
    Timer {
        id: play
        interval: 200
        repeat: false
        running: false
        onTriggered: {
            if (playMusic.bufferProgress == 1) {
                playMusic.play()
                play.stop()
            } else {
                play.restart()
            }
        }
    }
    function fixwidth() {
        if (root.subtitle != i18n("Choose Station") && root.title != i18n(
                    "Advanced Radio Player")) {
            var wid = Math.max(art.contentWidth, track.contentWidth,
                               alb.contentWidth)
            info.width = wid + 64 + units.gridUnit * 2.4 + urlart.width
        }
    }

    function isPlaying() {
        return playMusic.playbackState == MediaPlayer.PlayingState
    }
}
