import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/components"

Page {
	id: root
	//% "Feeds"
	title: qsTrId("opkgmanager_feeds")
	tryPop: opkgManager.tryPop

	required property var opkgManager
	property bool _loading

	Component.onCompleted: refreshFeeds()

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
		anchors.fill: parent

		delegate: ListNavigation {
			required property var modelData

			text: modelData.name
			caption: root.opkgManager.showCompact ? "" : modelData.url

			onClicked: Global.pageManager.pushPage(
				"qrc:/OpkgManager/OpkgPageSettingsFeedEdit.qml", {
					title: modelData.name,
					opkgManager: root.opkgManager,
					model: modelData,
					loadFeedsModelCallback: root.loadFeeds
				}
			)
		}
	}

	function loadFeeds(feeds, refreshFeedName, refreshModelCallback) {
		settingsListView.model = feeds
		// Refresh the model
		if (refreshModelCallback)
			for (var i = 0; i < feeds.length; i++) {
				if (feeds[i].name == refreshFeedName) {
					refreshModelCallback(feeds[i])}
		}
	}

	function refreshFeeds() {
		_loading = true
		root.opkgManager.loadFeeds(false, function(result) {
			if (result.success)
				loadFeeds(result.data)
			_loading = false
		})
	}

	OpkgActionsRow {
		id: actionsRow
		buttonModel: [
			 {
				//% "Add New Feed"
				text: qsTrId("opkgmanager_add_new_feed"),
				onClicked: function() {Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsFeedEdit.qml", {
							title: qsTrId("opkgmanager_add_new_feed"),
							opkgManager: root.opkgManager,
							model: {name:"", url:"", builtin: false, isNew: true},
							loadFeedsModelCallback: root.loadFeeds})}
			}
		]
	}
}