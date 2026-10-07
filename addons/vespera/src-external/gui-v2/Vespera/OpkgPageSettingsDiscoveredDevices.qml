import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/components"

Page {
	id: root
	title: CommonWords.discovered_devices

	required property OpkgManager opkgManager
	property string devicesUid: opkgManager.serviceUid + "/Discovered"
	property OpkgProgressText progressText
	property var popToPage

	OpkgDbusChildModel {
		id: devicesModel
		uid: root.devicesUid
		childId: "Port"
	}
	OpkgProgressText {}

 	GradientListView {
		id: listview
		header: PrimaryListLabel {
			horizontalAlignment: Text.AlignHCenter
			preferredVisible: root.progressText.running || listview.count ===0
			//% "No Usb devices discovered"
			text: root.progressText.running ? progressText.text : qsTrId("opkgmanager_no_devices_discovered")
		}

		model: devicesModel

		Component {
			id: opkgManagerFactory
			OpkgManager {
				function showToastNotification(level, message, duration) {
					Global.showToastNotification(level, message, duration)
				}
			}
		}

		delegate: ListNavigation {
			id: device
			required property var model

			text: CommonWords.device_info_title // "Device"
			secondaryText: model.value

			onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsDiscoveredDevice.qml",
				{"title": text,
				opkgManager: root.opkgManager,
				port: model.value,
				serviceUid: model.buddy.uid}
			 )
		}
	}
}