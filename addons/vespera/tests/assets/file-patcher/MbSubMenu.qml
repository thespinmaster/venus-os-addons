import QtQuick 2
import com.victron.velib 1.0

MbItem {
	id: root
	width: pageStack && pageStack.currentItem ? pageStack.currentItem.width : 0

	property string description
	property VBusItem item: VBusItem {}
	property string iconId: "icon-toolbar-enter"
	property bool check: false
	property bool indent: false
	default property alias values: _values.data

	MbTextDescription {
		id: checkText
		anchors {
			left: parent.left; leftMargin: mbStyle.marginDefault
			verticalCenter: parent.verticalCenter
		}
		width: root.indent ? 9 : 0
		text: root.check ? "√" : " "
	}

	MbTextDescription {
		id: name
		anchors {
			left: checkText.right; leftMargin: root.indent ? checkText.width : 0
			verticalCenter: parent.verticalCenter
		}
		text: root.description
	}

	MbRow {
		id: _values

		anchors {
			right: icon.left; rightMargin: mbStyle.marginDefault / 2
			verticalCenter: parent.verticalCenter
		}

		Repeater {
			id: repeater
			model: root.item.value && root.item.value.constructor === Array ? root.item.value.length : 1

			MbTextBlock {
				item.text: repeater.model === 1 ? root.item.text : root.item.value[index]
				opacity: item.text !== item.invalidText
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
		iconId: root.iconId ? root.iconId + (root.ListView.isCurrentItem ? "-active" : "") : ""
	}
// vespera 1.0
VesperaPageSettingsCustomMenus {}
}
