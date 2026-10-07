import QtQuick
import Victron.VenusOS
import "qrc:/OpkgManager/components/OpkgSingleton.js" as OpkgSingleton

DeviceListDelegate {
	id: root

	onDeviceChanged: {
		var isReload = OpkgSingleton.getIsReload()

		console.debug("OpkgManager: DeviceListDelegate::onDeviceChanged: isRelead=", isReload)

		// Using callLater fixes intermitten lock ups
		Qt.callLater(function () {
			parent.active = false
		})

		if (isReload) {
			Global.mainView.swipeView.animationEnabled = false
			Global.mainView.navBar.setCurrentIndex(-1)
		}

		if (!OpkgSingleton.OpkgCustomPageModelExists()) {
			OpkgSingleton.createOpkgCustomPageModel(Global.main)
		} else {
			console.debug("OpkgManager: OpkgSingleton exists")
		}

		if (isReload) {
			OpkgSingleton.setIsReload(false)

			Global.pageManager.popAllPages(1)

			Qt.callLater(function () {

				Global.mainView.navBar.setCurrentIndex(0)
				Global.mainView.swipeView.animationEnabled = true
			})

		}

	}
	// Component.onDestruction: {
	// 	console.debug("OpkgManager device delegate:DESTROYED")
	// }

}
