pragma ComponentBehavior: Bound
import QtQuick 2

MbPage {
	id: root
	title: qsTr("Packages")
	//tryPop: opkgManager.tryPop
	model: packagesModel
	pageToolbarHandler: customToolbar

  property var opkgManager
	property var test
	property bool _loading: true
	property var curPage: pageStack ? (pageStack.currentPage || pageStack.currentItem) : undefined
	property var packagesModel: []
	property MbStyle mbStyle: MbStyle {}

	 onOpkgManagerChanged: {
	 	if (opkgManager == undefined)
	 		return
	 	root.refreshPackages()
	 }

	Label {
		text: "Loading..."
		visible: root._loading
		anchors.centerIn: parent
		color: mbStyle.textColor
		onVisibleChanged: {
			root.listview.visible = !_loading
		}
	}


	delegate: OpkgHeaderDescriptionItem {
		required property var modelData
		id: headerItem
		header: modelData.packageName
		description: modelData.description
		showCompact: opkgManager.showCompact
		indicatorColor: (modelData.installedVersion && modelData.availableVersion
								? Qt.color("orange")
								: (modelData.installedVersion
									? Qt.color("#2969a1")
									: null))
		subpage: Component {
			OpkgPageSettingsPackageInstall {
				opkgManager: root.opkgManager
				model: root.opkgManager.snapshotObject(modelData)
				loadPackagesModelCallback: root.onLoadPackagesModel}
		}
	}

	function refreshPackages(force) {
		console.log("refreshPackages in")
		root._loading = true

		root.opkgManager.loadPackages(force, function(result) {
			console.log("loadPackages in")
			if (result.success)
				onLoadPackagesModel(result.data)
			root._loading = false
		})
	}

	function onLoadPackagesModel(packages, refreshPackageName, refreshModelCallback) {
		root.packagesModel = packages

		// Refresh the model
		if (refreshModelCallback)
			for (var i = 0; i < packages.length; i++) {
				if (packages[i].packageName == refreshPackageName) {
					refreshModelCallback(packages[i])}
		}
	}

	ToolbarHandler {
		id: customToolbar
		leftText: qsTr("Refresh")
		function leftAction(mouse) {
			if (!mouse)
				return
			if (root.opkgManager.running)
				return
			refreshPackages(true)
		}

	}

}