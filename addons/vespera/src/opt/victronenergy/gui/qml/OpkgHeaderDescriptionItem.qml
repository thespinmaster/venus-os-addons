import QtQuick 2
import com.victron.velib 1.0

MbItem {
	id: root
	width: (pageStack && pageStack.currentPage && pageStack.currentPage.width)
		|| (pageStack && pageStack.currentItem && pageStack.currentItem.width)
		|| 0

	defaultHeight: Math.max(mbStyle.itemHeight, columnRoot.implicitHeight)

	property var indicatorColor
	property string description
	property string header
	property string footer
	property bool showCompact: false
	property bool showFooter: true
	property int descriptionWrapMode: Text.WordWrap
	property VBusItem item: VBusItem {}
	property string iconId: "icon-toolbar-enter"
	property int spacing : 4

	Rectangle {
		width: mbStyle.marginTextHorizontal
		color : root.indicatorColor ? root.indicatorColor : mbStyle.backgroundColor
		anchors {
			left: parent.left
			top: parent.top
			bottom: parent.bottom
			bottomMargin: 1
		}
	}

	Column {
		id: columnRoot
		width: parent ? parent.width : 0

		spacing: root.spacing
		property bool isCurrentItem: root.ListView.isCurrentItem

		anchors {
			top: parent.top;
			topMargin: mbStyle.marginDefault
			bottom: parent.bottom;
		}

		MbTextDescription {
			id: header
			text: root.header || ""
			isCurrentItem: root.ListView.isCurrentItem
			visible: root.header || !root.showCompact
			anchors {
				left: parent.left; leftMargin: mbStyle.marginDefault + mbStyle.marginTextHorizontal
				right: parent.right
			}
		}

		MbTextDescription {
			id: description
			visible: !root.header || !root.showCompact
			text: root.description ? root.description : ""
			isCurrentItem: root.ListView.isCurrentItem
			wrapMode: root.descriptionWrapMode
			font.pixelSize: root.header ? 12 : mbStyle.fontPixelSize
			anchors {
				left: parent.left; leftMargin: mbStyle.marginDefault + mbStyle.marginTextHorizontal
				right: parent.right
			}
		}

		MbTextDescription {
			id: footer
			visible: root.showFooter && !root.showCompact
			text: root.showFooter ? root.footer : ""
			isCurrentItem: root.ListView.isCurrentItem
			font.pixelSize: root.header ? 12 : mbStyle.fontPixelSize
			anchors {
				left: parent.left; leftMargin: mbStyle.marginDefault + mbStyle.marginTextHorizontal
				right: parent.right
			}
		}
	}

	MbIcon {
		id: icon
		display: hasSubpage
		anchors {
			right: root.right; rightMargin: mbStyle.marginDefault
			verticalCenter: parent.verticalCenter
		}
		iconId: mbStyle.themer ? Themer.subMenuIconBinding(root.ListView.isCurrentItem, icon, root.iconId) : root.iconId
	}


}
