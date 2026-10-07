import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/components"

Page {
	id: root
	//% "Package Details"
	title: qsTrId("opkgmanager_package_details")
	tryPop: opkgManager?.tryPop

	required property var model
	required property OpkgManager opkgManager
	required property var loadPackagesModelCallback

	readonly property bool hasInstalled: model.installedVersion?.length > 0
	readonly property bool hasAvailable: model.availableVersion?.length > 0
	readonly property string actionLabel: hasInstalled && hasAvailable
			//% "Upgrade"
			? qsTrId("opkgmanager_package_upgrade")
			//% "Install"
			: qsTrId("opkgmanager_package_intsall")

	readonly property int hMargin: Theme.geometry_page_content_horizontalMargin + Theme.geometry_listItem_content_horizontalMargin
	readonly property int vMargin: Theme.geometry_listItem_content_verticalMargin

	Component.onCompleted: {
		opkgManager.setOutputLog(logViewer)
 	}

	Component.onDestruction: {
		if (opkgManager)
			opkgManager.setOutputLog(null)
 	}

	Column {
		id: column
		anchors {
			top: parent.top
			left: parent.left
			right: parent.right
			topMargin: root.vMargin
		}
		spacing: 0

		// package name, full width
		Label {
			width: parent.width
			leftPadding: root.hMargin
			rightPadding: root.hMargin
			topPadding: root.vMargin
			//bottomPadding: vMargin
			text: root.model.packageName
			font.pixelSize: Theme.font_size_body3
			color: Theme.color_font_primary
			wrapMode: Text.Wrap
		}
		// description, full width
		Label {
			width: parent.width
			leftPadding: root.hMargin
			rightPadding: root.hMargin
			topPadding: root.vMargin
			text: root.model.description
			font.pixelSize: Theme.font_size_body2
			color: Theme.color_font_secondary
			wrapMode: Text.Wrap
		}
		// installed / available — wraps when space is insufficient
		// secondary font/color
		Flow {
			width: parent.width
			leftPadding: root.hMargin
			rightPadding: root.hMargin
			topPadding: root.vMargin
			spacing: Theme.geometry_listItem_content_spacing

			// Label 1: Installed
			Row {
				spacing: Theme.geometry_listItem_content_spacing / 2
				Label {
					//% "Installed"
					text: qsTrId("opkgmanager_installed") + ":"
					font.pixelSize: Theme.font_size_body2
					color: Theme.color_font_secondary
				}
				Label {
					text: (root.hasInstalled)
							? root.model.installedVersion + (root.model.installedVersionSuffix ? "." + root.model.installedVersionSuffix : "")
							//% "none"
							: qsTrId("opkgmanager_none")
					font.pixelSize: Theme.font_size_body2
					color: Theme.color_font_primary
				}
			}

			// Label 2: Available — flows under Label 1 when not enough space
			Row {
				spacing: Theme.geometry_listItem_content_spacing / 2
				Label {
					//% "Available"
					text: qsTrId("opkgmanager_available")  + ":"
					font.pixelSize: Theme.font_size_body2
					color: Theme.color_font_secondary
				}
				Label {
					text: (root.hasAvailable)
							? root.model.availableVersion + (root.model.availableVersionSuffix ? "." + root.model.availableVersionSuffix : "")
							//% "none"
							: qsTrId("opkgmanager_none")
					font.pixelSize: Theme.font_size_body2
					color: Theme.color_font_primary
				}
			}
		}

		// Tertiary: feed
		Row {
			id: row
			leftPadding: root.hMargin
			topPadding: root.vMargin
			spacing: Theme.geometry_listItem_content_spacing / 2

			Label {
				//% "Feed"
				text: qsTrId("opkgmanager_feed") + ":"
				font.pixelSize: Theme.font_size_body1
				color: Theme.color_font_secondary
			}
			Label {
				text: root.model.feed
				font.pixelSize: Theme.font_size_body1
				color: Theme.color_font_primary
			}
		}

	}

	// Non-selectable, scrollable log area
	OpkgLogViewer {
		id: logViewer

		anchors {
			top: column.bottom; topMargin: root.vMargin
			bottom: actionsRow.top; bottomMargin: root.vMargin
			left: parent.left; leftMargin: root.hMargin
			right: parent.right; rightMargin: root.hMargin
		}
	}

	OpkgActionsRow {
		id: actionsRow
		buttonModel: [
			{
				//% "Remove"
				text: qsTrId("opkgmanager_remove"),
				enabled: !root.opkgManager.running && root.hasInstalled && root.model.packageName != "opkg-manager",
				onClicked: function() {
					root.opkgManager.removePackage(root.model.packageName, completionCallback)
				}
			},
			{ text: root.actionLabel,
				//visible: root.actionLabel.length > 0,
				enabled: !root.opkgManager.running && root.hasAvailable,
				onClicked: function() {
					if (!root.hasInstalled) {
						root.opkgManager.installPackage(root.model.packageName, completionCallback)
					} else {
						root.opkgManager.upgradePackage(root.model.packageName, completionCallback)
					}
				}
			}
		]
	}

	function completionCallback(result) {

		if (!result.success)
			return

			root.loadPackagesModelCallback?.(result.data, root.model.packageName, function(updatedModel) {
					root.model = updatedModel
			})

		logViewer.log("--- Finished " + result.operationName + ". Exit code: " + result.exitCode + ", status: " + result.exitStatus + " ---")
	}

}
