import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/components"

Page {
	id: root
	//% "Custom Devices"
	title: qsTrId("opkgmanager_custom_devices")
	tryPop: opkgManager.tryPop

	property OpkgManager opkgManager
	property string service: "com.victronenergy.opkgmanager"
	property string settings: "com.victronenergy.settings/Settings/OpkgManager"

	Component {
		id: opkgManagerFactory
		OpkgManager {
			function showToastNotification(level, message, duration) {
				Global.showToastNotification(level, message, duration)
			}
		}
	}

	Component.onCompleted: {
		if (opkgManager == null)
			opkgManager = opkgManagerFactory.createObject(root)
	}

	function toggleScan() {
		if (opkgManager.running) {
			opkgManager.cancel()
			return
		}

		progressText.start(CommonWords.scanning.arg("").slice(0, -1))
		opkgManager.usbScan(function (result) {
			if (progressText)
				progressText.stop()
		})
		showDiscoveredDevicesPage()
	}

	function showDiscoveredDevicesPage() {
		Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsDiscoveredDevices.qml", {
			opkgManager: root.opkgManager,
			progressText: progressText})
	}
	OpkgProgressText {id: progressText}

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
				onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsSavedDevices.qml", {"title": text, opkgManager: root.opkgManager})
			}

			ListNavigation {
				text: CommonWords.discovered_devices
				//secondaryText: subpage.model.count //TODO
				onClicked: root.showDiscoveredDevicesPage()
			}
		}
	}

}