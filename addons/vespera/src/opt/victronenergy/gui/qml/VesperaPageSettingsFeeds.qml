pragma ComponentBehavior: Bound
import QtQuick 2
import com.victron.velib 1.0

MbPage {
	id: root
	title: qsTr("Packages")
	//tryPop: vesperaManager.tryPop
	model: feedsModel
	pageToolbarHandler: customToolbar

	required property VesperaManager vesperaManager
	property bool _loading: true
	property var curPage: pageStack ? (pageStack.currentPage || pageStack.currentItem) : undefined
	property var feedsModel: []

	onVesperaManagerChanged: {
		root.refreshFeeds()
	}

	delegate: VesperaHeaderDescriptionItem {
		required property var modelData
		editable: true
		header: modelData.name
		description: "Url: " + modelData.url
		descriptionWrapMode: Text.WrapAtWordBoundaryOrAnywhere
		showCompact: vesperaManager.showCompact
		subpage: Component {
			VesperaPageSettingsFeedEdit{
					feedModel: vesperaManager.snapshotObject(modelData)
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
		root.vesperaManager.loadFeeds(false, function(result) {
			if (result.success)
				loadFeeds(result.data)
			_loading = false
		})
	}
	Component {
		id: editFeedPageComponent
		VesperaPageSettingsFeedEdit {}
	}

	ToolbarHandler {
		id: customToolbar
		rightText: "Add New Feed"

		function rightAction() {
			if (root.vesperaManager.running) {
				return
			}

			var feedModel = {name:"", description:"", builtin:false}
			var page = editFeedPageComponent.createObject(
				pageStack, {
					vesperaManager: root.vesperaManager,
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
