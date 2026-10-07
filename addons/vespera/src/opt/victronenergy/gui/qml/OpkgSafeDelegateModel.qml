import QtQuick 2

/*
OpkgSafeDelegateModel.qml
When a DelegateModel or a ListModel becomes empty,
 VisualModels crashes if that model is the final entry in its models list.
 This wrapper fixes that crash by adding a permanent visual item that is always
 present after the model; In this case the DelegateModel.
 The last item must also be visible.
 To keep the selection consistant we reject the selection if it is moved to the
 "invisible" Rectangle.
*/

VisualModels {
	id: root

	required property QAbstractItemModel model
	required property Component delegate
	property alias count: dm.count

	DelegateModel {
		id: dm
		model: root.model
		delegate: root.delegate
	}

	VisibleItemModel  {
		Rectangle {
			id: rect
			width:0; height:0
			property bool isCurrentItem: rect.ListView.isCurrentItem
			onIsCurrentItemChanged: {
				if (isCurrentItem && listview.currentIndex == listview.count-1) {
					Qt.callLater(function() {
						listview.decrementCurrentIndex()
						})
				}
			}
		}
	}
}