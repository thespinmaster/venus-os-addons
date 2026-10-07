import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils

MbPage {
	id: root
	title: qsTr("Open Package Manager")

	property var VesperaManager: VesperaManager {
		id: vesperaManager
		function showToastNotification(level, message, duration) {
			toast.createToast(message, duration);
		}
	}

	Component.onDestruction: {
		if (vesperaManager)
			vesperaManager.cleanup()
	}

	model: VisibleItemModel {
		MbSubMenu {
			description: qsTr("Packages")
			subpage: Component { VesperaPageSettingsPackages {vesperaManager: root.vesperaManager} }
		}
		MbSubMenu {
			description: qsTr("Feeds")
			subpage: Component { VesperaPageSettingsFeeds {vesperaManager: root.vesperaManager} }
		}

		MbSubMenu {
			id:cdi
			description: qsTr("Custom Devices")
			subpage: Component {VesperaPageSettingsDevices {title:cdi.description; vesperaManager:root.vesperaManager} }
		}

		MbSwitch {
			name: qsTr("Show Compact")
			bind: Utils.path("com.victronenergy.settings", "/Settings/Vespera/ShowCompact")
		}
		MbSwitch {
			name: qsTr("No Action")
			// description: "For testing installs, does not install"
			bind: Utils.path("com.victronenergy.settings", "/Settings/Vespera/NoAction")
		}

	}
}
