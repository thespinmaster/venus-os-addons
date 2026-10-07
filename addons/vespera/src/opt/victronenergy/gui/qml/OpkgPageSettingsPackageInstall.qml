import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils

MbPage {
	id: root
	title: qsTr("Package details")
	pageToolbarHandler: customToolbar

	required property var model
	required property OpkgManager opkgManager
	required property var loadPackagesModelCallback

	readonly property bool hasInstalled: model?.installedVersion.length > 0
	readonly property bool hasAvailable: model?.availableVersion.length > 0
	readonly property string actionLabel: hasInstalled && hasAvailable ? qsTr("Upgrade") : !hasInstalled ? qsTr("Install") : qsTr("")

	readonly property MbStyle mbStyle: MbStyle {}

	readonly property int hMargin: mbStyle.marginItemHorizontal
	readonly property int vMargin: mbStyle.marginItemVertical
	readonly property var primaryFontColor: root.mbStyle ? root.mbStyle.textColor : "#000000"
	readonly property int secondaryFontSize: Math.round(root.mbStyle.fontPixelSize * 0.8)
	readonly property var secondaryFontColor: mbStyle.color2

	Component.onCompleted: {
		opkgManager.setOutputLog(logViewer)
 	}
	Component.onDestruction: {
		opkgManager.setOutputLog(null)
	}

	// protect the back button from being pressed while processing commands.
 	MouseArea {
		x:0; y:-mbTools.height
		width: mbTools.height; height: mbTools.height
		visible: opkgManager.running
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

		// Primary: package name, full width
		Label {
			width: parent.width
			leftPadding: root.hMargin
			rightPadding: root.hMargin
			topPadding: root.vMargin
			text: root.model?.packageName
			color: root.primaryFontColor
			wrapMode: Text.Wrap
		}
		Label {
			width: parent.width
			leftPadding: root.hMargin
			rightPadding: root.hMargin
			topPadding: root.vMargin
			text: root.model?.description
			color: root.primaryFontColor
			font.pixelSize: root.secondaryFontSize
			wrapMode: Text.Wrap
		}
		// Secondary: installed / available — wraps when space is insufficient
		Flow {
			width: parent.width
			leftPadding: root.hMargin
			rightPadding: root.hMargin
			topPadding: root.vMargin
			//spacing: mbStyle.marginItemHorizontal

			// Label 1: Installed
			Row {
				spacing: mbStyle.marginItemHorizontal
				Label {
					text: qsTr("Installed:")
					font.pixelSize: root.secondaryFontSize
					color: root.secondaryFontColor
				}
				Label {
					text: (root.hasInstalled)
							? root.model?.installedVersion + (root.model.installedVersionSuffix ? "." + root.model.installedVersionSuffix : "")
							: qsTr("none")
					font.pixelSize: root.secondaryFontSize
					color: root.primaryFontColor
				}
			}

			// Label 2: Available
			Row {
				leftPadding: mbStyle.marginItemHorizontal
				spacing: mbStyle.marginItemHorizontal
				Label {
					text: qsTr("Available:")
					font.pixelSize: root.secondaryFontSize
					color: root.secondaryFontColor
				}
				Label {
					text: (root.hasAvailable)
							? root.model?.availableVersion + (root.model.availableVersionSuffix ? "." + root.model.availableVersionSuffix : "")
							: qsTr("none sd sd ")
					font.pixelSize: root.secondaryFontSize
					color: root.primaryFontColor
				}
			}
			Row {
				id: row
				//leftPadding: root.hMargin
				topPadding: root.vMargin
				spacing: mbStyle.marginItemHorizontal

				Label {
					text: qsTr("Feed:")
					font.pixelSize: root.secondaryFontSize
					color: root.secondaryFontColor
				}
				Label {
					text: root.model?.feed
					font.pixelSize: root.secondaryFontSize
					color: root.primaryFontColor
				}
			}
		}

	}

	// Non-selectable, scrollable log area
	OpkgLogViewer {
		id: logViewer

		anchors {
			top: column.bottom; topMargin: root.vMargin
			bottom: parent.bottom; bottomMargin: root.vMargin
			left: parent.left; leftMargin: root.hMargin
			right: parent.right; rightMargin: root.hMargin
		}
	}

	ToolbarHandler {
		id: customToolbar
		leftText: root.model && !root.opkgManager.running && root.hasInstalled && root.model.packageName != "opkg-manager" ? "Remove" : ""
		function leftAction() {
			root.opkgManager.removePackage(root.model.packageName, completionCallback)
		}

		rightText: root.actionLabel
		function rightAction() {
			/*
			// test model update
			var updatedModel = {
					packageName: "New Package",
					description: "My new description",
					installedVersion: "5.2",
					availableVersion: "6.2", feed:"test-feed" }
			root.model = updatedModel
			return
			*/

			if (!root.hasInstalled) {
				root.opkgManager.installPackage(root.model.packageName, completionCallback)
			} else {
				root.opkgManager.upgradePackage(root.model.packageName, completionCallback)
			}
		}
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
