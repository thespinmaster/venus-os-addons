import QtQuick 2
import Theming 1.0
import "opkg-utils.js" as OpkgUtils

QtObject {

  
	Component.onCompleted: {
    //console.log("Component.onCompleted:" + description)

		if (icon && icon.iconId) {
 
		icon.iconId = Qt.binding(function() {
		  return Themer.subMenuIconBinding(root.ListView.isCurrentItem, icon, root.iconId)
		})
 
		}
	}
}
