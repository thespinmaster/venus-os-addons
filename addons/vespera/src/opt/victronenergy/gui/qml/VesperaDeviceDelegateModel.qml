import QtQuick 2
import com.victron.velib 1.0
import Vespera 1.0

VesperaSafeDelegateModel {
	id: root

	//"Sid" all custom Class Types i.e. com.victronenergy.inetbox.xxx, com.vistronenergy.tank.xxx
	//"Sid2" custom Class Types i.e. com.victronenergy.inetbox.xxx
	property string child_id: "Sid"

	model: VeQItemSortTableModel {
		model: VeQItemChildModel {
			model: VesperaDeviceModel.deviceList
			childId: root.child_id
		}
		dynamicSortFilter: true
		filterFlags: VeQItemSortTableModel.FilterInvalid
	}

	delegate: VesperaDevice {
		sid: model.item.value
		bindPrefix: model.buddy.uid
	}

}