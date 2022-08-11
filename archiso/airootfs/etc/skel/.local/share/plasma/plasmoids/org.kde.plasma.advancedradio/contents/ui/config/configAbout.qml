import QtQuick 2.1
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.3

Item {
    id: page
    clip: true
    property string cfg_version: plasmoid.configuration.version
    aboutData: {
        "displayName": "Advanced Radio Player",
        "componentName": "radio",
        "shortDescription": i18n("Radio player with editable list of stations"),
        "homepage": "https://store.kde.org/p/1313987",
        "version": cfg_version,
        "authors": [{
                        "name": "Yuriy Saurov"
                    }],
        "credits": [{
                        "name": "Ilya Bizyaev",
                        "task": i18n("fixing errors")
                    }, {
                        "name": "Evgeniy Mediankin",
                        "task": i18n("idea for search")
                    }],
        "translators": [{
                            "name": "bukowski",
                            "task": "cs_CZ"
                        }, {
                            "name": "Nico Lubnau",
                            "task": "de_DE"
                        }, {
                            "name": "Nacho Seixo",
                            "task": "es_Es, gl_ES"
                        }, {
                            "name": "Kimmo Kujansuu",
                            "task": "fi_FI"
                        }, {
                            "name": "Sergio Lobianco",
                            "task": "pt_BR"
                        }, {
                            "name": "Yuriy Saurov",
                            "task": "ru_RU"
                        }, {
                            "name": "Tarık Buğra SARUHAN",
                            "task": "tr_TR"
                        }, {
                            "name": "Serhii V. Golovko",
                            "task": "uk_UA"
                        }],
        "licenses": [{
                         "name": "MIT"
                     }],
        "copyrightStatement": "© 2019-2020 Yuriy Saurov",
        "otherText": i18n(
                    "If you want to help translate the application into your language<br>or suggest corrections or new features, write me on dr@i-glu4it.ru.")
    }

    property var aboutData

    Component {
        id: licencePage
        ScrollablePage {
            property alias text: content.text
            QQC2.TextArea {
                id: content
                readOnly: true
            }
        }
    }

    Component {
        id: personDelegate

        RowLayout {
            height: implicitHeight + (Units.smallSpacing * 2)

            spacing: Units.smallSpacing * 2
            Icon {
                width: Units.iconSizes.smallMedium
                height: width
                source: "user"
            }
            QQC2.Label {
                text: modelData.task ? ("%0 - (%1)").arg(
                                           i18n(modelData.name)).arg(
                                           i18n(modelData.task)) : i18n(
                                           modelData.name)
            }
        }
    }

    FormLayout {
        id: form

        GridLayout {
            columns: 2

            //             Layout.fillWidth: true
            Icon {
                Layout.rowSpan: 2
                Layout.preferredHeight: Units.iconSizes.huge
                Layout.preferredWidth: height
                Layout.maximumWidth: page.width / 3
                Layout.rightMargin: Units.largeSpacing
                source: page.aboutData.componentName
            }
            Heading {
                Layout.fillWidth: true
                text: page.aboutData.displayName + " - " + page.aboutData.version
            }
            Heading {
                Layout.fillWidth: true
                level: 2
                wrapMode: Text.WordWrap
                text: i18n(page.aboutData.shortDescription)
            }
        }

        Separator {
            Layout.fillWidth: true
        }

        Heading {
            FormData.isSection: true
            text: i18n("Copyright")
        }
        Label {
            Layout.leftMargin: Units.gridUnit
            text: aboutData.copyrightStatement
            visible: text.length > 0
        }
        Label {
            Layout.leftMargin: Units.gridUnit
            text: "<a href='" + aboutData.homepage + "'>" + aboutData.homepage + "</a>"
            visible: text.length > 0
            onLinkActivated: {
                Qt.openUrlExternally(aboutData.homepage)
            }
        }

        Component {
            id: licenseTextItem
            RowLayout {
                Layout.leftMargin: Units.smallSpacing
                Label {
                    Layout.topMargin: Units.smallSpacing
                    text: i18n("License: %0").arg(modelData.name)
                }
            }
        }

        Repeater {
            model: aboutData.licenses
            delegate: licenseTextItem
        }

        Separator {
            Layout.fillWidth: true
        }

        Heading {
            FormData.isSection: visible
            text: i18n("Libraries in use")
            visible: Settings.information ? true : false
        }
        Repeater {
            model: Settings.information
            delegate: Label {
                Layout.leftMargin: Units.gridUnit
                id: libraries
                text: modelData
            }
        }
        Separator {
            Layout.fillWidth: true
        }
        Heading {
            Layout.fillWidth: true
            FormData.isSection: visible
            text: i18n("Author")
            visible: aboutData.authors.length > 0
        }
        Repeater {
            model: aboutData.authors
            delegate: personDelegate
        }
        Separator {
            Layout.fillWidth: true
        }
        Heading {
            height: visible ? implicitHeight : 0
            FormData.isSection: visible
            text: i18n("Credits")
            visible: repCredits.count > 0
        }
        Repeater {
            id: repCredits
            model: aboutData.credits
            delegate: personDelegate
        }
        Separator {
            Layout.fillWidth: true
        }
        Heading {
            height: visible ? implicitHeight : 0
            FormData.isSection: visible
            text: i18n("Translators")
            visible: repTranslators.count > 0
        }
        Repeater {
            id: repTranslators
            model: aboutData.translators
            delegate: personDelegate
        }
        Separator {
            Layout.fillWidth: true
        }

        QQC2.Label {
            Layout.leftMargin: Units.gridUnit
            width: parent.width
            text: i18n(aboutData.otherText)
            visible: text.length > 0
        }
    }
}
