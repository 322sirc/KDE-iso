import QtQuick 2.12
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0

MouseArea {
    Plasmoid.toolTipMainText: ""
    Plasmoid.toolTipSubText: "" //Remove default tooltip
    id: panelIconWidget
    property int wheelDelta: 0
    anchors.fill: parent
    hoverEnabled: true
    onClicked: plasmoid.expanded = !plasmoid.expanded
    onWheel: {
        volumeTimer.restart()
        var delta = wheel.angleDelta.y || wheel.angleDelta.x
        wheelDelta += delta
        while (wheelDelta >= 120) {
            wheelDelta -= 120
            if (playMusic.volume < 1) {
                playMusic.volume += 0.05
            }
        }
        while (wheelDelta <= -120) {
            wheelDelta += 120
            if (playMusic.volume > 0) {
                playMusic.volume -= 0.05
            }
        }
        tooltip.mainText = playMusic.volume == 0 ? i18n(
                                                       "Audio") : i18n("Volume")
        tooltip.subText = playMusic.volume == 0 ? i18n("Muted") : Math.round(
                                                      playMusic.volume * 100) + "%"
        tooltip.image = ""
        tooltip.icon = setVolumeIcon(playMusic.volume)
    }
    onEntered: {
        tooltip.showToolTip()
    }
    Connections {
        target: root
        function onTooltipimageChanged() {
            if (panelIconWidget.containsMouse) {
                tooltip.showToolTip()
            }
        }
    }

    PlasmaCore.IconItem {
        source: "audio-radio"
        anchors.fill: parent
        overlays: isPlaying()
                  && playMusic.status == 6 ? ["media-default-track"] : []
    }

    PlasmaCore.ToolTipArea {
        id: tooltip
        location: PlasmaCore.Types.Floating
        onAboutToShow: {
            setToolTip()
        }
    }
    Timer {
        id: volumeTimer
        running: false
        repeat: false
        interval: PlasmaCore.Units.humanMoment
        onTriggered: {
            setToolTip()
        }
    }

    function setToolTip() {
        tooltip.mainText = root.artist != "" ? root.artist : Plasmoid.title
        tooltip.subText = root.artist != "" ? root.song : Plasmoid.metaData.description
        tooltip.icon = isPlaying()
                && playMusic.status == 6 ? "audio-x-generic" : "audio-radio"
        tooltip.image = root.artist != "" ? root.tooltipimage : ""
    }

    function setVolumeIcon(volume) {
        var prefix = "audio-volume"
        var icon = null
        if (volume <= 0.0) {
            icon = prefix + "-muted"
        } else if (volume <= 0.25) {
            icon = prefix + "-low"
        } else if (volume <= 0.75) {
            icon = prefix + "-medium"
        } else {
            icon = prefix + "-high"
        }
        return icon
    }
}
