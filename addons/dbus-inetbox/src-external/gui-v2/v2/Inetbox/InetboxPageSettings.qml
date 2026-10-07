import QtQuick 2
import Victron.VenusOS

Page {
	id: root
	//% "Inetbox settings"
	title: qsTrId("inetbox_settings")

	property var pageUri:"qrc:/Inetbox/MotorhomePage.qml"
	property var customPagesArray: customPagesItem.valid ? JSON.parse(customPagesItem.value): []

	VeQuickItem {
		id: customPagesItem
		uid: !!Global.systemSettings ? Global.systemSettings.serviceUid + "/Settings/Vespera/CustomNavPages" : ""
	}

	GradientListView {
		id: settingsListView

		model: VisibleItemModel {

			ListSwitch {
				id: show_mh_page_switch
				checkable: true
				checked: root.customPagesArray.includes(root.pageUri)

				//% "Show Motorhome Page"
				text: qsTrId("inetbox_show_motorhome_page")
				writeAccessLevel: VenusOS.User_AccessType_User

				onCheckedChanged: {
					const idx = root.customPagesArray.indexOf(root.pageUri)
					if (checked) {
						if (idx !== -1) return
						root.customPagesArray.push(root.pageUri)
					} else {
						if (idx === -1) return
						root.customPagesArray.splice(idx, 1)
					}

					customPagesItem.setValue(JSON.stringify(root.customPagesArray))
				}
			}

			ListText {
				text: qsTrId("vespera_version")
				secondaryText: GuiPluginLoader.plugin("Inetbox").version
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
