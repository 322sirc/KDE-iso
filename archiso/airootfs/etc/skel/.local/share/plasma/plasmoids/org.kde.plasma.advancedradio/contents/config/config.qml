import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("Stations")
        icon: "radio"
        source: "config/configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Search")
        icon: "search"
        source: "config/configSearch.qml"
    }
}
