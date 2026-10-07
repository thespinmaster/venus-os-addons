import QtQuick 2
import com.victron.velib 1.0

MbPage {
	id: root

	required property VesperaManager vesperaManager
	property string service: "com.victronenergy.vespera"
	property string settings: "com.victronenergy.settings/Settings/Vespera"

	function scan() {
		if (vesperaManager.running)
			return

		progressText.start("Scanning")
		vesperaManager.usbScan(function (result) {
			progressText.stop()
		})
	}

	VesperaProgressText {id: progressText}

	model: VisibleItemModel {
		MbOK {
			id: scanItem
			description: qsTr("Scan for devices")
			value: progressText.running ? progressText.text : qsTr("Press to scan")
			onClicked: scan()
			show: userHasWriteAccess
		}

		MbSubMenu {
			id: savedDevices
			description: qsTr("Saved devices")
			item.value: subpage.model.count;
			subpage: VesperaPageSavedDevices {title: savedDevices.description; vesperaManager: root.vesperaManager}
		}

		MbSubMenu {
			id: discoveredDevices
			description: qsTr("Discovered devices")
			//item.bind: service + "/DiscoveredCount"
			item.value: subpage.model.count
			subpage: VesperaPageDiscoveredDevices {
					title: discoveredDevices.description
					vesperaManager: root.vesperaManager
				}

		}
	}

}