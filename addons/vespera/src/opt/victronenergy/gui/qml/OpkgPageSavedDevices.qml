import QtQuick 2

MbPage {
	id: root;

	model: OpkgDeviceDelegateModel {}
	pageToolbarHandler: model.count > 0 ? customToolbar : undefined

	required property var opkgManager
	onActiveChanged: {
		dialog.close()
	}

	OpkgDialog {id: dialog}
 
	function removeDevicePrompt() {
		if (root.opkgManager.running)
			return

		var itm = root.listview.currentItem
		dialog.buttonsModel = [{text: qsTr("No")}, {id:"y", text:qsTr("Yes")}]
		dialog.show(qsTr("Remove device ") + itm.description, "", function(id) {
			if (id == "y")
				opkgManager.removeDevice(itm.sid);
		})
	}

	ToolbarHandler {
		id: customToolbar
		leftText: !root.opkgManager.running
				? model.count > 0
					? qsTr("Remove")
					: ""
				: qsTr("Removing...")
		function leftAction() {
			root.removeDevicePrompt()
		}
	}
}
