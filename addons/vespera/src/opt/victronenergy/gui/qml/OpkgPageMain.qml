pragma ComponentBehavior: Bound
import QtQuick 2
import com.victron.velib 1.0
import "opkg-utils.js" as OpkgUtils
import OpkgManager 1.0

QtObject {
	id: opkgRoot

  property VeQuickItem moveSettingsToTop: VeQuickItem {
    uid: "dbus/com.victronenergy.settings/Settings/OpkgManager/CustomMenus/PageMain/PageSettings"
    onValueChanged: opkgRoot.movePageSettingsToTop()
  }

  Component.onCompleted: {
		movePageSettingsToTop()
		insertCustomDevicesModel()
	}

	function insertCustomDevicesModel() {

		const OPKG_DELEGATE_MODEL_INDEX = 0
		const DELEGATE_MODEL_INDEX = 1

		var modelIndexes = getModelIndexes()

		if (modelIndexes[OPKG_DELEGATE_MODEL_INDEX] !== -1
			|| modelIndexes[DELEGATE_MODEL_INDEX] === -1)
			return // OPKG_DELEGATE_MODEL_INDEX already exists or DELEGATE_MODEL_INDEX not found; bail

		var insertIndex = modelIndexes[DELEGATE_MODEL_INDEX] + 1

		var cmp =  Qt.createComponent('OpkgDeviceDelegateModel.qml')
		var COMPONENT_READY=1
		if (cmp.status !== COMPONENT_READY) {
			console.error("Failed to create component:", cmp.errorString());
			return
		}

		//Use Sid2/ so we only show custom devices (not tank/temperature/battery devices)
		var obj =  cmp.createObject(root.listview.contentItem,{ child_id: "Sid2"})

		model.insert(insertIndex, obj)

	}

  function movePageSettingsToTop(modelIndexes) {

		const OPKG_DELEGATE_MODEL_INDEX = 0
		const DELEGATE_MODEL_INDEX = 1
		const SETTINGS_MODEL_INDEX = 2

		if (modelIndexes == undefined)
			modelIndexes = getModelIndexes() || [-1,-1,-1]

		if (modelIndexes[DELEGATE_MODEL_INDEX] === -1 || modelIndexes[SETTINGS_MODEL_INDEX] === -1)
			return // not found, bail

    var action = opkgRoot.moveSettingsToTop.value

    if (action == "^") {
      // move to top

			if (modelIndexes[2] < modelIndexes[1])
        return // already moved
			root.model.move(modelIndexes[SETTINGS_MODEL_INDEX], 0, 1)
    } else {
      // revert
      if (modelIndexes[2] > modelIndexes[1])
        return  // already moved
			//Note: root.model.count = ALL the visible items NOT the count of root.model.models
			// YET root.model.move operates on root.model.models
			// root.model.models is an array (use length not count)

			var idx = modelIndexes[OPKG_DELEGATE_MODEL_INDEX] !== -1
				? modelIndexes[OPKG_DELEGATE_MODEL_INDEX] : modelIndexes[SETTINGS_MODEL_INDEX]
			root.model.move(modelIndexes[SETTINGS_MODEL_INDEX], idx,  1)
    }
  }

	function getModelIndexes() {
		var indexes = []

		indexes.push(OpkgUtils.findIndex(root.model, "OpkgDeviceDelegateModel_"))
		indexes.push(OpkgUtils.findIndex(root.model, "QQmlDelegateModel("))
		indexes.push(OpkgUtils.findIndex(root.model, "QQmlVisibleItemModel(",
			function (m,itm,idx,lvl) {
					var menuIdx = OpkgUtils.findIndex(itm, "MbSubMenu_QMLTYPE_",
						function (m,itm,idx,lvl) {
							if ((itm.subpage.toString() || "").startsWith("PageNotifications_QMLTYPE_"))
								return idx
							return -1 // continue
						})
				return menuIdx == -1 ? -1 : idx //if found bubble the parent idx up (not menuIdx)
			}))
		return indexes
	}

}
