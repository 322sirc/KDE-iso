import QtQuick 2.12
import QtMultimedia 5.8
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM
import org.kde.plasma.plasmoid 2.0

Item {
    id: root
    property string artist
    property string artisturl
    property string song
    property string songurl
    property string title: Plasmoid.title
    property bool isError: false
    property string tooltipimage
    property string albumimage
    property string album
    property string albumurl
    property int lastPlay: -1
    property bool isConnected: networkStatus.networkStatus === i18nd(
                                   "plasma_applet_org.kde.plasma.networkmanagement",
                                   "Connected")
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    StationsModel {
        id: stationsModel
    }
    Component.onCompleted: {
        reloadStationsModel()
    }
    Connections {
        target: plasmoid.configuration
        function onServersChanged() {
            playMusic.stop()
            reloadStationsModel()
        }
    }

    MediaPlayer {
        id: playMusic
        property string title: isPlaying()
                               && playMusic.metaData.title ? playMusic.metaData.title : null
        onTitleChanged: {
            if (isPlaying()) {
                getInfo(playMusic.metaData.title)
            }
        }
        onError: {
            isError = true
            errorTimer.start()
        }
        onStopped: {
            playMusic.stop()
            playMusic.source = ""
            root.title = Plasmoid.title
            root.albumimage = ""
            root.tooltipimage = ""
            root.album = ""
            root.albumurl = ""
            root.artist = ""
            root.artisturl = ""
            root.song = ""
            root.songurl = ""
        }
        volume: 0.75
    }

    Timer {
        id: errorTimer
        running: false
        repeat: false
        interval: 5000
        onTriggered: {
            isError = false
        }
    }

    Plasmoid.compactRepresentation: CompactRepresentation {}

    Plasmoid.fullRepresentation: FullRepresentation {
        id: dialogItem
        anchors.fill: parent
        focus: true
    }
    function isPlaying() {
        return playMusic.playbackState === MediaPlayer.PlayingState
    }
    function reloadStationsModel() {
        playMusic.stop()
        stationsModel.clear()
        try {
            var servers = JSON.parse(plasmoid.configuration.servers)
            for (var i = 0; i < servers.length; i++) {
                if (servers[i].active) {
                    stationsModel.append(servers[i])
                }
            }
        } catch (e) {
            console.log(e)
        }
    }

    PlasmaNM.NetworkStatus {
        id: networkStatus
        onNetworkStatusChanged: {
            if (networkStatus.networkStatus === i18nd(
                        "plasma_applet_org.kde.plasma.networkmanagement",
                        "Connected")) {
                root.isConnected = true
            } else {
                console.log("Connection lost")
                root.isConnected = false
            }
        }
    }
    function getInfo(data) {
        if (data !== undefined && data.indexOf('-') !== -1) {
            var strings // Magic to check non-standard artists/songs like "A-ha - Minor earth major sky"
            if (data.indexOf(' - ') !== -1) {
                strings = data.split(' - ')
            } else {
                strings = data.split('-')
            }
            var artist = strings[0].trim(), song = strings[1].trim()
            var xmlhttp = new XMLHttpRequest()
            var url = "http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key=ada39a6834a3be4d641cc1aec7e64d48&artist=" + encodeURIComponent(
                        artist) + "&track=" + encodeURIComponent(
                        song) + "&autocorrect=1&format=json"
            xmlhttp.onreadystatechange = function () {
                if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                    setInfo(JSON.parse(xmlhttp.responseText))
                }
            }
            xmlhttp.open("GET", url)
            xmlhttp.send()
            function setInfo(arr) {
                root.artist = (arr.track
                               && arr.track.artist) ? (arr.track.artist.name) : artist
                root.song = (arr.track) ? (arr.track.name) : song
                root.title = (isPlaying(
                                  )) ? root.artist + " - " + root.song : Plasmoid.title
                root.artisturl = (arr.track
                                  && arr.track.artist) ? (arr.track.artist.url) : ""
                root.songurl = (arr.track
                                && arr.track.url) ? (arr.track.url) : ""

                root.albumimage = arr.track && arr.track.album
                        && arr.track.album.image[1]['#text'] ? arr.track.album.image[1]['#text'] : ""
                root.tooltipimage = arr.track && arr.track.album
                        && arr.track.album.image[0]['#text'] ? arr.track.album.image[0]['#text'] : ""
                root.album = arr.track && arr.track.album
                        && arr.track.album.title
                        && arr.track.album.title != "" ? arr.track.album.title : ""
                root.albumurl = arr.track && arr.track.album
                        && arr.track.album.url
                        && arr.track.album.url != "" ? arr.track.album.url : ""
            }
        } else {
            root.title = isPlaying() && playMusic.metaData.title
                    && !playMusic.metaData.title.startsWith(
                        "{") ? playMusic.metaData.title : Plasmoid.title // "{"  fix for some stations
        }
    }
}
