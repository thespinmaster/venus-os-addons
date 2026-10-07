import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/components"

Page {
	id: page
	//% "Open Package Manager"
	title: qsTrId("opkgmanager_open_package_manager")
	Component.onDestruction: opkgManager?.cleanup()

	OpkgManager {
		id: opkgManager
		traceEnabled: true
		function showToastNotification(level, message, duration) {
			Global.showToastNotification(level, message, duration)
			// console.log("opkgManager:" + level + ", " + message)
		}
	}

	GradientListView {
		id: settingsListView

		model: VisibleItemModel {

			ListNavigation {
				//% "Packages"
				text: qsTrId("opkg_packages")
				onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsPackages.qml", {
						"title": text,
						"opkgManager": opkgManager
					})
			}
			ListNavigation {
				//% "Feeds"
				text: qsTrId("opkg_feeds")
				onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsFeeds.qml", {
						"title": text,
						"opkgManager": opkgManager
					})
			}

			ListNavigation {
				topInset: Theme.geometry_listItem_itemSeparator_height
				bottomInset: Theme.geometry_listItem_itemSeparator_height
				//% "Custom Devices"
				text: qsTrId("opkg_custom_devices")
				onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsDevicesList.qml", {
						"title": text,
						"opkgManager": opkgManager
					})
			}

			ListSwitch {
				dataItem.uid: opkgManager.showCompactSetting.uid
				//% "Show Compact"
				text: qsTrId("opkg_show_compact")
			}
			ListSwitch {
				dataItem.uid: opkgManager.noActionSetting.uid
				//% "No Action"
				text: qsTrId("opkg_no_action")
			}
			ListText {
				//% "Version"
				text: qsTrId("opkg_version")
				secondaryText: GuiPluginLoader.plugin("OpkgManager").version
			}
			ListLink {
				id: documentation

				//% "Documentation"
				text: qsTrId("pagecontrollableloads_documentation")
				url: "https://thespinmaster.github.io/venus-os-addons/"
			}
		}
	}
}
