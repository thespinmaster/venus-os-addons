pragma Singleton
import QtQuick 2
import com.victron.velib 1.0

QtObject {

	readonly property VeQItemSortTableModel deviceList: VeQItemSortTableModel {
		model: VeQItemTableModel {
			uids: ["dbus/com.victronenergy.settings/Settings/Devices"]
			flags: VeQItemTableModel.AddChildren |
					VeQItemTableModel.AddNonLeaves |
					VeQItemTableModel.DontAddItem
		}
		dynamicSortFilter: true
		filterRegExp: "^dbus\/com\.victronenergy\.settings\/Settings\/Devices\/sid_[^/]+$"
		filterFlags: VeQItemSortTableModel.FilterOffline
	}

}