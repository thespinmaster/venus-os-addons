import QtQuick 2
import com.victron.velib 1.0

//Gets all the child nodes of specified name (Role)
// under the provided path (uid);
// using an optional filter on the uid
// Will update the rows on changes
// Use onRowCountChanged to monitor changes
// Use rowCount to get the count of items
// In delegates use model.value to get the value of the childId
// i.e. if childId is "ProductName" value will return "Foo Product"
// Use model.buddy to get the parent node
//   model.buddy.uid for the path, model.buddy.id for the path name

VeQItemSortTableModel {
	id: root

	property alias childId: childModel.childId
	property string uid
	property alias filterRegExp: sortTable.filterRegExp
	property var valueDelegate

	model: VeQItemChildModel {
		id: childModel
		model: VeQItemSortTableModel {
			id: sortTable
			model: VeQItemTableModel {
				uids: [root.uid]
				flags: VeQItemTableModel.AddChildren |
						VeQItemTableModel.AddNonLeaves |
						VeQItemTableModel.DontAddItem
			}
			dynamicSortFilter: true
			filterFlags: VeQItemSortTableModel.FilterOffline
		}

	}
	dynamicSortFilter: true
	filterFlags: VeQItemSortTableModel.FilterInvalid

	readonly property var values: {
		// Referencing rowCount creates a QML binding dependency
		// so subscribers are notified whenever the model changes
		var _count = rowCount;

		return new Proxy({}, {
			get: function(target, prop) {
				// Handle array .length check
				if (prop === "length")
					return root.rowCount

				// Intercept integer array index lookups (e.g., values[i])
				var i = Number(prop)
				if (Number.isInteger(i) && i >= 0 && i < root.rowCount) {
					// 1. Get the model index
					var idx = root.index(i, VeQItemTableModel.ValueColumn);
					// 2. Fetch data (Qt::DisplayRole, Qt::UserRole, or a custom VeQItem role)
					var value = root.data(idx, VeQItemTableModel.ValueRole);
					if (valueDelegate) {
						var uid = root.data(idx, VeQItemTableModel.UniqueIdRole);
						var item = root.data(idx, VeQItemTableModel.ItemRole);
						var buddy = item.itemParent()
						var model = {
							id: root.childId,
							uid:uid,
							value: value,
							buddyUid: buddy.uid,
							buddyId: buddy.id}
						return valueDelegate(model)
					}
					return value
				}

				return target[prop]
			}
		})
	}
}