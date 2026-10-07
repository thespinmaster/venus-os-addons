import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/components"

Page {
	id: root
	//% "Saved USB serial device"
	title: qsTrId("opkgmanager_saved_usb_serial_device")

	required property var opkgManager
	required property string name
	required property string serviceUid
	//required property var deviceRemovedCallback

	property var removingDeviceText: progressText.running ? progressText.text : ""

	property var jsonUsbProps: usbPropsItem.valid ? JSON.parse(usbPropsItem.value) : {}

	VeQuickItem {
		id: usbPropsItem
		uid: root.serviceUid + "/UsbProps"
	}
	OpkgProgressText { id: progressText }

	GradientListView {
		header: SettingsColumn {

			width: parent.width
			bottomPadding: spacing

			SettingsListHeader {
				//% "Device properties"
				text: qsTrId("opkgmanager_device_properties")
			}
			ListText {
				//% "Device name"
				text: qsTrId("opkgmanager_device_name")
				secondaryText: root.name
			}
		}

		model: root.jsonUsbProps

		delegate: ListText {
				required property var model
				width: parent.width
				text: model.name
				secondaryText: model.value
		}

		footer: SettingsColumn {
			width: parent.width
			topPadding: spacing
			ListButton {
				//% "Remove Device"
				secondaryText: qsTrId("opkgmanager_remove_device")
				onClicked: Global.dialogLayer.open(modeConfirmationDialogComponent)
			}
		}
	}

	function removeDevice() {
		var sid = root.serviceUid.split('/').pop()
		sid = sid.replace(/^sid_/, "");
		
		//% "Removing Device"
		progressText.start(qsTrId("opkgmanager_removing_device"))

		root.opkgManager.removeDevice(
			sid, function(result) {
				if (progressText)
					progressText.stop()
				if (result.success) {
					//% "Device successfully removed"
					var successMessage = qsTrId("opkgmanager_device_successfully_removed")
					Global.showToastNotification(VenusOS.Notification_Info, successMessage, 5000)
				}
			}
		)
		Global.pageManager.popPage()
	}

	Component {
		id: modeConfirmationDialogComponent

		ModalWarningDialog {
			//% "Are you sure?"
			title: qsTrId("opkgmanager_are_you_sure")
			//% "Clicking yes will permanently remove this devices settings"
			description: qsTrId("opkgmanager_remove_device_description")
			dialogDoneOptions: VenusOS.ModalDialog_DoneOptions_OkAndCancel
			onAccepted: root.removeDevice()
		}
	}
}
