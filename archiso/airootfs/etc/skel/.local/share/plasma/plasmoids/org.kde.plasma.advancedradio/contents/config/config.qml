import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "radio"
        source: "config/configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-color"
        source: "config/configAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Import/Export")
        icon: "grid-rectangular"
        source: "config/configExport.qml"
    }
    ConfigCategory {
        name: i18n("Search")
        icon: "search"
        source: "config/configSearch.qml"
    }
    ConfigCategory {
        name: i18n("About")
        icon: "help-about-symbolic"
        source: "config/configAbout.qml"
    }
}
