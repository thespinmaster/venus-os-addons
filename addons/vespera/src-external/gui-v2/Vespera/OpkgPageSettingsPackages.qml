import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/components"

Page {
	id: root
	//% "Packages"
	title: qsTrId("opkgmanager_packages")
	tryPop: opkgManager.tryPop

	required property OpkgManager opkgManager
	property bool _loading: true

	Component.onCompleted: root.refreshPackages()

	Label {
		//% "Loading..."
		text: qsTrId("opkgmanager_loading")
		visible: root._loading
		anchors.centerIn: parent
		font.pixelSize: Theme.font_size_body3
	}

	GradientListView {
		id: settingsListView
		clip: true
		visible : !root._loading
		anchors {
			top: parent.top
			left: parent.left
			right: parent.right
			bottom: actionsRow.top
		}

		delegate: ListNavigation {
			required property var modelData

			indicatorColor: (modelData.installedVersion && modelData.availableVersion
											? Theme.color_orange
											: (modelData.installedVersion
													? Theme.color_blue
													: Qt.rgba(0,0,0,0)))
			text: modelData.packageName + "  " + modelData.installedVersion
			caption: root.opkgManager.showCompact ? "" : modelData.description
			onClicked: Global.pageManager.pushPage(
				"qrc:/OpkgManager/OpkgPageSettingsPackageInstall.qml",
				{ title: text,
					opkgManager: root.opkgManager,
					model: root.opkgManager.snapshotObject(modelData),
					loadPackagesModelCallback: root.onLoadPackagesModel}

			)
		}
	}

	function refreshPackages(force) {
		_loading = true
		opkgManager.loadPackages(force, function(result) {
				if (result.success)
					onLoadPackagesModel(result.data)
				_loading = false
			})
	}

	function onLoadPackagesModel(packages, refreshPackageName, refreshModelCallback) {
		settingsListView.model = packages;

		// Refresh the model
		if (refreshModelCallback)
			for (var i = 0; i < packages.length; i++) {
				if (packages[i].packageName == refreshPackageName) {
					refreshModelCallback(packages[i])}
		}
	}

	OpkgActionsRow {
		id: actionsRow
		buttonModel: [
			{
				//% "Refresh"
				text: qsTrId("opkgmanager_refresh"),
				enabled: root.opkgManager ? (!root.opkgManager.running && visible) : false,
				onClicked: function() {
					root.refreshPackages(true)
				}
			}
		]
	}

}