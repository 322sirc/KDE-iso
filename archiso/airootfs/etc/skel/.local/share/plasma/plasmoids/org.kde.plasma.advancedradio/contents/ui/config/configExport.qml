import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import ".."

ColumnLayout {
    id: page
    Layout.fillWidth: true
    property bool lock: true
    Label {
        text: i18n("Attention! Configuration changes immediately.<br>Use with caution.")
        color: "red"
        wrapMode: Text.WordWrap
    }
    RowLayout {
        Button {
            id: copybutton
            text: i18n("Copy")
            iconName: "edit-copy"
            onClicked: {
                notifchange.stop()
                exportData.copyselect()
                notif.color = "green"
                notif.text = i18n("Configuration are copied to clipboard.")
                notifchange.start()
            }
        }
        Button {
            id: lockbutton
            text: page.lock ? i18n("Unlock") : i18n("Lock")
            iconName: page.lock ? "unlock" : "lock"
            onClicked: {
                notifchange.stop()
                page.lock ? page.lock = false : page.lock = true
                notif.text = page.lock ? i18n("Configuration are locked.") : i18n(
                                             "Configuration are unlocked!")
                notif.color = page.lock ? "green" : "red"
                notifchange.start()
            }
        }
        Button {
            id: pastebutton
            text: i18n("Paste")
            iconName: "edit-paste"
            onClicked: {
                notifchange.stop()
                notif.color = page.lock ? "red" : "green"
                notif.text = page.lock ? i18n("Unlock before restore configuration!") : i18n(
                                             "Configuration are restored.")
                page.lock ? '' : exportData.pasteselect()
                notifchange.start()
            }
        }
    }
    Label {
        id: notif
        text: i18n(" ")
    }
    Timer {
        id: notifchange
        running: false
        repeat: false
        onTriggered: {
            notif.color = ""
            notif.text = i18n(" ")
        }
        interval: 5000
    }

    ConfigBase64JsonString {
        id: exportData
        Layout.fillHeight: true

        Base64JsonString {
            id: configStations
            writing: exportData.base64JsonString.writing
            defaultValue: []
        }

        defaultValue: {
            var data = {}
            var configKeyList = plasmoid.configuration.keys()
            for (var i = 0; i < configKeyList.length; i++) {
                var configKey = configKeyList[i]
                var configValue = plasmoid.configuration[configKey]
                if (typeof configValue === "undefined"
                        || configKey !== 'servers') {
                    continue
                }
                data[configKey] = configValue
            }
            return data
        }

        function serialize() {
            var newValue = parseText(textArea.text)
            var configKeyList = plasmoid.configuration.keys()
            for (var i = 0; i < configKeyList.length; i++) {
                var configKey = configKeyList[i]
                var propValue = newValue[configKey]
                if (typeof propValue === "undefined"
                        || configKey !== 'servers') {
                    continue
                }
                if (plasmoid.configuration[configKey] != propValue) {
                    plasmoid.configuration[configKey] = propValue
                }
            }
        }
        function copyselect() {
            textArea.selectAll()
            textArea.copy()
            textArea.deselect()
        }
        function pasteselect() {
            textArea.selectAll()
            textArea.paste()
            textArea.deselect()
        }
    }
}
