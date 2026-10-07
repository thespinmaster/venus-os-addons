pragma ComponentBehavior: Bound

import QtQuick 2
import Victron.VenusOS

Item {
  id: root

	property int spacing: Theme.geometry_listItem_content_spacing
	implicitHeight: childrenRect.height
	property int defaultButtonWidth: 200
	
	anchors {
		left: parent.left; leftMargin: Theme.geometry_page_content_horizontalMargin + Theme.geometry_listItem_content_horizontalMargin
		right: parent.right; rightMargin: root.anchors.leftMargin
		bottom: parent.bottom; bottomMargin: Theme.geometry_listItem_content_verticalMargin
	}

}