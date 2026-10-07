import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/components"

Page {
	id: root

	required property OpkgManager opkgManager
	property string devicesUid: Global.systemSettings.serviceUid + "/Settings/Devices"

	OpkgDbusChildModel {
		id: devicesModel
		uid: root.devicesUid
		childId: "ProductName"
	}

 	GradientListView {
		id: listview
		header: PrimaryListLabel {
			horizontalAlignment: Text.AlignHCenter
			preferredVisible: listview.count === 0
			//% "No Usb devices saved"
			text: qsTrId("opkgmanager_no_devices_saved")
		}

		model: devicesModel

		delegate: ListNavigation {
			id: device
			required property var model

			VeQuickItem {
				id: customNameItem
				uid: model.buddy.uid + "/CustomName"
			}

			text: customNameItem.valid && customNameItem.value
					? customNameItem.value
					: model.value
						? model.value
						: CommonWords.device_info_title
			property bool deviceAdded: false

			function onDeviceAddedCallback(added) {
				if (added !== undefined)
					deviceAdded = added
				return deviceAdded
			}

			onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsSavedDevice.qml",
				{"title": text,
				opkgManager: root.opkgManager,
				name: model.value,
				serviceUid: model.buddy.uid
				})
		}
	}

}