import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "hueLights"

    StyledText {
        width: parent.width
        text: "Hue Lights settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure enabled light services"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: lightServicesColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: lightServicesColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Enabled services"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }
			
			ToggleSetting {
				settingKey: "openhue-cli:enable"
				label: "Hue Lights (via openhue-cli)"
				description: "Enable Hue Lights through openhue-cli. Note: requires openhue-cli to be installed and configured with `openhue-cli setup`"
				defaultValue: true
			}
                   
		}
    }

    StyledRect {
        width: parent.width
        height: openhueCliConfigColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: openhueCliConfigColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Options for Hue Lights via openhue-cli"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

			StringSetting {
				settingKey: "openhue-cli:path"
				label: "Custom path for openhue-cli"
				description: "Set a custom path for openhue-cli (optional)"
				placeholder: "openhue-cli"
				defaultValue: "openhue-cli"
			}
        }
    }
}
