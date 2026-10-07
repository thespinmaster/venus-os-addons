import QtQuick 2
import com.victron.velib 1.0

MbPage {
	id: root

	required property OpkgManager opkgManager

	OpkgDbusChildModel {
		id: devicesModel
		uid: "dbus/com.victronenergy.opkgmanager/Discovered"
		filterRegExp: "\/sid_[^/]+$"
		childId: "Port"
	}

	model: OpkgSafeDelegateModel {

		model: devicesModel

		delegate: MbSubMenu {
			id: discoveredDevice
			required property var model
			description: model.value

			property bool deviceAdded: false

			function onDeviceAddedCallback(added) {
				if (added !== undefined)
					deviceAdded = added
				return deviceAdded
			}

			subpage: Component {
					OpkgPageDiscoveredDevice {
						opkgManager: root.opkgManager
						serviceUid: discoveredDevice.model.buddy.uid
						port: discoveredDevice.model.value
						deviceAddedCallback: discoveredDevice.onDeviceAddedCallback}
				}
			}

	}
}