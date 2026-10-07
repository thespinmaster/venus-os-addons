import QtQuick 2

MbPage {
	id: root;

	model: VesperaDeviceDelegateModel {}
	pageToolbarHandler: model.count > 0 ? customToolbar : undefined

	required property VesperaManager vesperaManager
	onActiveChanged: {
		dialog.close()
	}

	VesperaDialog {id: dialog}

	function removeDevicePrompt() {
		if (root.vesperaManager.running)
			return

		var itm = root.listview.currentItem
		dialog.buttonsModel = [{text: qsTr("No")}, {id:"y", text:qsTr("Yes")}]
		dialog.show(qsTr("Remove device ") + itm.description, "", function(id) {
			if (id == "y")
				vesperaManager.removeDevice(itm.sid);
		})
	}

	ToolbarHandler {
		id: customToolbar
		leftText: !root.vesperaManager.running
				? model.count > 0
					? qsTr("Remove")
					: ""
				: qsTr("Removing...")
		function leftAction() {
			root.removeDevicePrompt()
		}
	}
}
