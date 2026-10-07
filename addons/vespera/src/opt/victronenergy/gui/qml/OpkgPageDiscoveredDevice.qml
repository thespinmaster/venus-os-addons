import QtQuick 2
import com.victron.velib 1.0

MbPage {
	id: root
	title: "Add USB serial device"

	required property var opkgManager
	required property string serviceUid
	required property string port
	required property var deviceAddedCallback

	property string selectedServiceTypePath: ""
	property var addingDeviceText: progressText.running ? progressText.text : ""
	property bool deviceAdded: deviceAddedCallback !== undefined ? deviceAddedCallback() : false
	property var usbProps: usbPropsItem.value ? JSON.parse(usbPropsItem.value) : {}

	pageToolbarHandler: addDeviceToolbarHandler

	VeQuickItem {
		id: usbPropsItem
    uid: serviceUid + "/UsbProps"
  }

	model: VisualModels {
		VisibleItemModel {
			MbItemOptions {
				id: selectServiceType

				description: qsTr("Serial Device Service")
				unknownOptionText: qsTr("Press to select service")
				message: root.serviceTypesModel?.length === 0 ? qsTr("No custom devices currently installed") : ""
				value: root.selectedServiceTypePath
				onOptionSelected: function (newValue) { root.onSerialDeviceServiceSelected(newValue) }
				//Fix for spacebar not working after DelegateModel use!
				Keys.onSpacePressed: { edit() }
			}
			MbItemRow { description: qsTr("Port")
				values: [MbTextBlock { item.text: root.port} ]}
		}

		DelegateModel {
			model: root.usbProps
			delegate: MbItemRow { description: modelData.name
				values: [MbTextBlock { item.text: modelData.value} ]}
		}

	}

	OpkgProgressText { id: progressText}
	Component  { id: mbOptionFactory; MbOption {}}

	OpkgDbusChildModel {
		id: customDevices
		uid: "dbus/com.victronenergy.settings/Settings/OpkgManager/Devices"
		childId: "ProductName"
		valueDelegate: function (model) {
			return mbOptionFactory.createObject(root, {description:model.value, value: model.buddyId})
		}
		//MbOptions uses list<MbOption> so we need this hack
		onValuesChanged: selectServiceType.possibleValues = Array.prototype.slice.call(values)
	}

	function onSerialDeviceServiceSelected(newValue)	{
		var changed = root.selectedServiceTypePath != "" && root.selectedServiceTypePath != newValue
		root.selectedServiceTypePath = newValue
	}

	function addDevice() {
		if (root.deviceAdded || !root.selectedServiceTypePath)
			return

		var checkStable = 1

		progressText.start("Adding Device")

		root.opkgManager.bindDeviceToService(
			deviceProps.hash, deviceProps.port, root.selectedServiceTypePath, checkStable,
			function(result) {
				progressText.stop()
				if (result.success) {
						deviceAddedCallback(true)
					toast.createToast("Device Added Successfully\nThe service will start shortly...", 5000)
				}
			}
		)
		//pageStack.pop();
	}
	function cancel() {
		pageStack.pop();
	}

	ToolbarHandler {
		id: addDeviceToolbarHandler
	  leftText: progressText.running
			? root.addingDeviceText
		 	: !root.deviceAdded && root.selectedServiceTypePath
				? qsTr("Save")
				: ""
		rightText: qsTr("Cancel")
		function leftAction() { root.addDevice() }
		function rightAction() { root.cancel() }
	}
}
