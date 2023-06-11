import QtQuick 2.12
import QtQuick.Layouts 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras

PlasmaComponents3.ItemDelegate {
    id: listItem
    property bool isTry: false
    width: parent ? parent.width : 0
    clip: true
    background: PlasmaCore.FrameSvgItem {
        imagePath: "widgets/viewitem"
        prefix: (stationView.currentIndex === model.index && isPlaying()
                 || listItem.hovered ? "hover" : "normal")
        anchors.fill: parent
        opacity: stationView.currentIndex === model.index && isPlaying()
                 && playMusic.status == 6 ? 1 : 0.5
    }
    contentItem: ColumnLayout {
        spacing: infoLayout.visible ? PlasmaCore.Units.smallSpacing : 0
        RowLayout {
            id: listItemLayout
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            implicitHeight: PlasmaCore.Units.gridUnit + PlasmaCore.Units.smallSpacing
            clip: true
            PlasmaCore.IconItem {
                id: listIcon
                source: stationView.currentIndex === model.index
                        && listItem.hovered ? stationView.currentIndex === model.index
                                              && !listItem.hovered ? isPlaying()
                                                                     && !listItem.hovered ? 'media-playback-start' : 'media-playback-stop' : 'media-playback-stop' : 'media-playback-start'
                implicitWidth: PlasmaCore.Units.iconSizes.sizeForLabels
                implicitHeight: PlasmaCore.Units.iconSizes.sizeForLabels
                visible: !tryToPlayIndicator.visible && listItem.hovered
                         || stationView.currentIndex === model.index
                         && playMusic.bufferProgress === 1
            }
            PlasmaComponents3.Label {
                text: model.index + 1
                visible: !listItem.hovered
                         && stationView.currentIndex !== model.index
                Layout.minimumWidth: PlasmaCore.Units.iconSizes.sizeForLabels
                Layout.preferredHeight: PlasmaCore.Units.iconSizes.sizeForLabels
                width: height
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
            }

            PlasmaComponents3.BusyIndicator {
                id: tryToPlayIndicator
                running: visible
                visible: stationView.currentIndex === model.index
                         && playMusic.bufferProgress < 1
                implicitWidth: PlasmaCore.Units.iconSizes.sizeForLabels
                implicitHeight: PlasmaCore.Units.iconSizes.sizeForLabels
            }
            Rectangle {
                id: trackRect
                clip: true
                color: "transparent"
                Layout.fillWidth: true
                height: parent.height
                PlasmaComponents3.Label {
                    id: trackName
                    Layout.fillWidth: true
                    text: model.name
                    anchors.verticalCenter: parent.verticalCenter
                    font.weight: stationView.currentIndex === model.index
                                 && isPlaying()
                                 && playMusic.status == 6 ? Font.Bold : Font.Normal
                    maximumLineCount: 1
                    Layout.alignment: Qt.AlignLeft
                    elide: Text.ElideRight
                    XAnimator {
                        target: trackName
                        from: 0
                        to: -trackName.width
                        duration: Math.round(
                                      Math.abs(
                                          to - from) / PlasmaCore.Units.gridUnit
                                      * (PlasmaCore.Units.longDuration
                                         + PlasmaCore.Units.shortDuration))
                        running: listItem.hovered
                                 && trackName.width > trackRect.width
                        loops: 1
                        onFinished: {
                            from = trackRect.width
                            if (listItem.hovered) {
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

            PlasmaComponents3.ToolButton {
                id: expandToggleButton
                implicitWidth: PlasmaCore.Units.iconSizes.sizeForLabels
                implicitHeight: PlasmaCore.Units.iconSizes.sizeForLabels
                visible: stationView.currentIndex === model.index
                         && root.artisturl != "" && root.songurl != ""
                display: PlasmaComponents3.AbstractButton.IconOnly
                icon.name: infoLayout.expanded ? "collapse" : "expand"
                onClicked: infoLayout.toggleExpanded()
            }
            TapHandler {
                target: listItemLayout
                onTapped: {
                    isError = false
                    errorTimer.stop()
                    stationView.currentIndex = model.index
                    refreshServer(model.index)
                    infoLayout.expanded = false
                }
                function refreshServer(index) {
                    if (isPlaying() && playMusic.source == stationsModel.get(
                                index).hostname && lastPlay == index) {
                        stationView.currentIndex = -1
                        playMusic.stop()
                    } else {
                        playMusic.stop()
                        playMusic.source = stationsModel.get(index).hostname
                        playMusic.play()
                    }
                    lastPlay = model.index
                }
            }
        }
        ColumnLayout {
            id: infoLayout
            property bool expanded: false
            Layout.fillWidth: true
            width: parent.width
            clip: true
            Layout.margins: 0
            spacing: PlasmaCore.Units.smallSpacing
            visible: stationView.currentIndex === model.index && expanded
                     && root.artist != ""
            opacity: expanded ? 1.0 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: PlasmaCore.Units.veryLongDuration
                    easing.type: Easing.InOutCubic
                }
            }
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: parent.width
            Image {
                source: root.albumimage
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            }
            PlasmaComponents3.ToolButton {
                icon.name: "view-media-artist"
                text: root.artist
                Layout.alignment: Qt.AlignHCenter
                onClicked: Qt.openUrlExternally(root.artisturl)
                visible: text != ""
                Layout.maximumWidth: parent.width
            }
            PlasmaComponents3.ToolButton {
                icon.name: "view-media-track"
                text: root.song
                Layout.alignment: Qt.AlignHCenter
                onClicked: Qt.openUrlExternally(root.songurl)
                visible: text != ""
                Layout.maximumWidth: parent.width
            }
            PlasmaComponents3.ToolButton {
                icon.name: "view-media-album-cover"
                text: root.album
                Layout.alignment: Qt.AlignHCenter
                onClicked: Qt.openUrlExternally(root.albumurl)
                visible: text != ""
                Layout.maximumWidth: parent.width
            }
            function toggleExpanded() {
                expanded = !expanded
            }
        }
    }
}
