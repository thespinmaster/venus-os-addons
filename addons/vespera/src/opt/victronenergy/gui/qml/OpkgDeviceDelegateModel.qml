import QtQuick 2
import com.victron.velib 1.0
import OpkgManager 1.0

OpkgSafeDelegateModel {
	id: root

	//"Sid" all custom Class Types i.e. com.victronenergy.inetbox.xxx, com.vistronenergy.tank.xxx
	//"Sid2" custom Class Types i.e. com.victronenergy.inetbox.xxx
	property string child_id: "Sid"

	model: VeQItemSortTableModel {
		model: VeQItemChildModel {
			model: OpkgDeviceModel.deviceList
			childId: root.child_id
		}
		dynamicSortFilter: true
		filterFlags: VeQItemSortTableModel.FilterInvalid
	}

	delegate: OpkgDevice {
		sid: model.item.value
		bindPrefix: model.buddy.uid
	}

}