import QtQuick 2
import Victron.VenusOS
import "qrc:/Vespera/components" as Vespera

Page {
	id: root
	//% "Custom Devices"
	title: qsTrId("vespera_custom_devices")
	tryPop: vesperaManager.tryPop

	property Vespera.VesperaManager vesperaManager
	property string service: "com.victronenergy.vespera"
	property string settings: "com.victronenergy.settings/Settings/Vespera"

	Component {
		id: vesperaManagerFactory
		Vespera.VesperaManager {
			function showToastNotification(level, message, duration) {
				Global.showToastNotification(level, message, duration)
			}
		}
	}

	Component.onCompleted: {
		if (vesperaManager == null)
			vesperaManager = vesperaManagerFactory.createObject(root)
	}

	function toggleScan() {
		if (vesperaManager.running) {
			vesperaManager.cancel()
			return
		}

		progressText.start(CommonWords.scanning.arg("").slice(0, -1))
		vesperaManager.usbScan(function (result) {
			if (progressText)
				progressText.stop()
		})
		showDiscoveredDevicesPage()
	}

	function showDiscoveredDevicesPage() {
		Global.pageManager.pushPage("qrc:/Vespera/PageSettingsDiscoveredDevices.qml", {
			vesperaManager: root.vesperaManager,
			progressText: progressText})
	}
	Vespera.ProgressText {id: progressText}

	GradientListView {
		model: VisibleItemModel {

			ListButton {
				// "Scan for devices"
				text: qsTrId("page_settings_modbus_scan_for_devices")
				secondaryText: progressText.running  ? progressText.text : CommonWords.scan_action
				onClicked: root.toggleScan()
				preferredVisible: userHasWriteAccess
			}

			ListNavigation {
				// "Saved devices"
				text: qsTrId("page_settings_modbus_saved_devices")
				//secondaryText: subpage.model.count //TODO
				onClicked: Global.pageManager.pushPage("qrc:/Vespera/PageSettingsSavedDevices.qml", {"title": text, vesperaManager: root.vesperaManager})
			}

			ListNavigation {
				text: CommonWords.discovered_devices
				//secondaryText: subpage.model.count //TODO
				onClicked: root.showDiscoveredDevicesPage()
			}
		}
	}

}