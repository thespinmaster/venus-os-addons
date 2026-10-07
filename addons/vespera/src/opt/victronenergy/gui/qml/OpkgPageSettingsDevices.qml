import QtQuick 2
import com.victron.velib 1.0

MbPage {
	id: root

	required property OpkgManager opkgManager
	property string service: "com.victronenergy.opkgmanager"
	property string settings: "com.victronenergy.settings/Settings/OpkgManager"

	function scan() {
		if (opkgManager.running)
			return

		progressText.start("Scanning")
		opkgManager.usbScan(function (result) {
			progressText.stop()
		})
	}

	OpkgProgressText {id: progressText}

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
			subpage: OpkgPageSavedDevices {title: savedDevices.description; opkgManager: root.opkgManager}
		}

		MbSubMenu {
			id: discoveredDevices
			description: qsTr("Discovered devices")
			//item.bind: service + "/DiscoveredCount"
			item.value: subpage.model.count
			subpage: OpkgPageDiscoveredDevices {
					title: discoveredDevices.description
					opkgManager: root.opkgManager
				}

		}
	}

}