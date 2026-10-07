pragma ComponentBehavior: Bound
import QtQuick 2
import com.victron.velib 1.0

MbPage {
	id: root
	title: qsTr("Packages")
	//tryPop: opkgManager.tryPop
	model: feedsModel
	pageToolbarHandler: customToolbar

	required property var opkgManager
	property bool _loading: true
	property var curPage: pageStack ? (pageStack.currentPage || pageStack.currentItem) : undefined
	property var feedsModel: []

	onOpkgManagerChanged: {
		root.refreshFeeds()
	}

	delegate: OpkgHeaderDescriptionItem {
		required property var modelData
		editable: true
		header: modelData.name
		description: "Url: " + modelData.url
		descriptionWrapMode: Text.WrapAtWordBoundaryOrAnywhere
		showCompact: opkgManager.showCompact
		subpage: Component {
			OpkgPageSettingsFeedEdit{
					feedModel: opkgManager.snapshotObject(modelData)
					loadFeedsModelCallback: root.loadFeeds
			}

		}
	}
	function loadFeeds(feeds, refreshFeedName, refreshModelCallback) {
		root.feedsModel = feeds
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
	Component {
		id: editFeedPageComponent
		OpkgPageSettingsFeedEdit {}
	}

	ToolbarHandler {
		id: customToolbar
		rightText: "Add New Feed"

		function rightAction() {
			if (root.opkgManager.running) {
				return
			}

			var feedModel = {name:"", description:"", builtin:false}
			var page = editFeedPageComponent.createObject(
				pageStack, {
					opkgManager: root.opkgManager,
					isNew: true,
					feedModel: feedModel,
					loadFeedsModelCallback: root.loadFeeds
					});

			if (page) {
				pageStack.push(page);
			}
		}
	}


}
