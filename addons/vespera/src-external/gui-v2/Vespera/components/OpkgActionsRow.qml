import QtQuick 2
import Victron.VenusOS

Row {
  id: root

  //property list<QtObject> buttonModel
	property var buttonModel: []

	layoutDirection: Qt.RightToLeft

	anchors {
		left: parent.left; leftMargin: Theme.geometry_page_content_horizontalMargin + Theme.geometry_listItem_content_horizontalMargin
		right: parent.right; rightMargin: root.anchors.leftMargin
		bottom: parent.bottom; bottomMargin: Theme.geometry_listItem_content_verticalMargin
	}

  spacing: Theme.geometry_listItem_content_spacing

  Repeater {
	  model: root.buttonModel

	  delegate: ListItemButton {
		required property var modelData

			width: modelData.width === undefined
				? Math.max(Theme.geometry_listItem_textField_minimumWidth, implicitWidth)
				: modelData.width
			text: modelData.text === undefined ? "" : modelData.text
		  enabled: modelData.enabled === undefined ? true : modelData.enabled
		  onClicked: modelData.onClicked()
		  visible: modelData.visible === undefined ? true : modelData.visible
	  }
  }
}