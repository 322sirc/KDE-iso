import QtQuick 2.12
import QtQuick.Layouts 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasmoid 2.0

PlasmaExtras.Representation {
    id: fullRepresentation
    Layout.minimumWidth: PlasmaCore.Units.gridUnit * 14
    Layout.minimumHeight: PlasmaCore.Units.gridUnit * 18
    Layout.maximumWidth: PlasmaCore.Units.gridUnit * 56
    Layout.maximumHeight: PlasmaCore.Units.gridUnit * 36
    collapseMarginsHint: true
    readonly property var appletInterface: Plasmoid.self
    header: PlasmaExtras.PlasmoidHeading {
        id: header
        focus: true
        visible: true
        RowLayout {
            spacing: 0
            Rectangle {
                Layout.fillWidth: true
                implicitWidth: fullRepresentation.width
                width: fullRepresentation.width
                implicitHeight: heading.height
                Layout.topMargin: PlasmaCore.Units.smallSpacing
                Layout.bottomMargin: PlasmaCore.Units.smallSpacing
                color: "transparent"
                clip: true
                onWidthChanged: {
                    if (isPlaying()) {
                        header.calculateAnimation()
                    } else {
                        anim.stop()
                        heading.x = -heading.width / 2 + fullRepresentation.width / 2
                    }
                }

                PlasmaExtras.Heading {
                    id: heading
                    maximumLineCount: 1
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.title
                    level: 1
                    onTextChanged: {
                        if (isPlaying()) {
                            header.calculateAnimation()
                        } else {
                            anim.stop()
                            heading.x = -heading.width / 2 + fullRepresentation.width / 2
                        }
                    }
                }
            }

            XAnimator {
                id: anim
                target: heading
                easing.type: Easing.Linear
                duration: Math.round(
                              Math.abs(to - from) / PlasmaCore.Units.gridUnit
                              * (PlasmaCore.Units.longDuration + PlasmaCore.Units.shortDuration))
            }
        }
        function calculateAnimation() {
            anim.from = width + PlasmaCore.Units.gridUnit
            anim.to = -heading.width
            anim.loops = Animation.Infinite
            anim.restart()
        }
    }

    PlasmaComponents3.ScrollView {
        id: scrollView
        anchors.fill: parent
        PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff
        contentWidth: availableWidth - contentItem.leftMargin - contentItem.rightMargin
        contentItem: ListView {
            id: stationView
            leftMargin: PlasmaCore.Units.smallSpacing
            rightMargin: PlasmaCore.Units.smallSpacing
            topMargin: PlasmaCore.Units.smallSpacing
            bottomMargin: PlasmaCore.Units.smallSpacing
            model: stationsModel
            enabled: isConnected
            focus: true
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            delegate: MediaListItem {}
            Connections {
                target: playMusic
                function onError() {
                    stationView.currentIndex = -1
                }
            }
        }
    }
    footer: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            Rectangle {
                implicitWidth: fullRepresentation.width
                width: fullRepresentation.width
                Layout.preferredHeight: childrenRect.height
                Layout.topMargin: PlasmaCore.Units.smallSpacing
                Layout.bottomMargin: PlasmaCore.Units.smallSpacing
                color: "transparent"
                PlasmaComponents3.Label {
                    id: subtext
                    font: PlasmaCore.Theme.smallestFont
                    width: parent.width
                    clip: true
                    color: isError
                           || !isConnected ? PlasmaCore.ColorScope.negativeTextColor : PlasmaCore.ColorScope.textColor
                    text: !isConnected ? i18n("Check internet connection...") : root.isError ? i18n("Error: ") + playMusic.errorString : isPlaying() && playMusic.status == 6 ? i18n("Bitrate: ") + Math.round(playMusic.metaData.audioBitRate / 1000) + 'Kb/s, ' + i18n("Genre: ") + playMusic.metaData.genre : playMusic.bufferProgress < 1 && playMusic.status != 1 ? i18n("Buffering...") + ' ' + Math.round(playMusic.bufferProgress * 100) + "%" : i18n("Choose station and enjoy...")
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }
    }
}
