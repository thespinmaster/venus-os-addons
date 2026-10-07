pragma ComponentBehavior: Bound
import QtQuick 2
import com.victron.velib 1.0

MbPage {
	id: root
	title: qsTr("Edit Feed")
	pageToolbarHandler: customToolbar
	
	required property var feedModel
	required property OpkgManager opkgManager
	required property var loadFeedsModelCallback
	property bool isNew: false
	property string _removeButtonText: isNew ? "Cancel" : "Remove"
	property string _saveButtonText: "Save"

	model: VisibleItemModel {
		MbEditBox {
			id: feedNameTextField
			readonly: !userHasWriteAccess || (isNew ? false : feedModel?.builtin ?? true)
			useVirtualKeyboard: false
			description: qsTr("Name")
			maximumLength: 20
			enableSpaceBar: false
			item.value: (!isNew && root.feedsModel) ? feedModel.name : ""
		}

		OpkgEditBoxLargeText {
			id: feedUrlTextField
			readonly: !userHasWriteAccess || (isNew ? false : feedModel?.builtin ?? true)
			description: qsTr("Url")
			maximumLength: 256
			matchString: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ~!@#$%^&*()-_=+[]{}\\;:|/.,<>?"
			enableSpaceBar: false
			item.value:  (!isNew && root.feedsModel) ? feedModel.url : ""
		}

		MbTextDescription {
			text: "(Readonly)"
			opacity: 0.5
			isCurrentItem: false
			width: parent ? parent.width : 0
			horizontalAlignment: Text.AlignHCenter
			visible: !isNew && feedModel?.builtin
		}
	}

	ToolbarHandler {
		id: customToolbar
		//leftIcon: (feedModel?.builtin) ? "" : "icon-toolbar-cancel"
		//rightIcon: (feedModel?.builtin) ? "" :"icon-toolbar-ok"
		leftText: !feedModel.builtin ? root._removeButtonText : ""
		function leftAction() {
			if (root.isNew) {
				pageStack.pop()
			} else {
				root.remove()
			}
		}
		rightText: !feedModel.builtin ? root._saveButtonText : ""
		function rightAction() {root.save()}
	}

	function remove() {
		if (root._builtin || opkgManager.running)
			return

		var completedCallback = function(result) {
			if (!result.success) {
				root._removeButtonText = "Remove"
				return
			}

			loadFeedsModelCallback?.(result.data)
			pageStack.pop()
		}

		root._removeButtonText = "Removing..."
		opkgManager.removeFeed(root.model.name, completedCallback)

	}

	function save() {
		if (root._builtin || opkgManager.running)
			return

		var status1 = root.validateFeedName()
		var status2 = root.validateFeedUrl()
		var error = status1 && status2
			? status1 + "\n  " + status2
			: status1
				? status1
				: status2

		if (error) {
			toast.createToast(qsTr(error), 3000, "icon-info-active");
			return
		}

		var feedName = feedNameTextField.text
		var feedUrl = feedUrlTextField.text

		var completedCallback = function(result) {
			if (!result.success) {
				root._saveButtonText = "Save"
				return
			}
			root.title = "Edit Feed" // update breadcrumb
			root._isNew = false
			loadFeedsModelCallback?.(result.data, feedName, root.refreshModel)

		}

		root._saveButtonText = "Saving..."

		if (root._isNew) {
			opkgManager.addFeed(feedName, feedUrl, completedCallback)
		} else {
			opkgManager.updateFeed(feedName, feedUrl, model.name, completedCallback)
		}
	}


	function validateFeedName() {
		var text = feedNameTextField.text
		console.log("validateFeedName:" + text)
		// only alphanumeric, no spaces or symbols
		// must contain at least one letter (prevents "12345")
		if (!/^[A-Za-z0-9-]+$/.test(text) || (!/[A-Za-z]/.test(text))) {
			//% "'%1' is not a valid IP address."
			// qsTrId("ip_address_input_not_valid").arg(trimmed)
			return "Invalid Name"
		}
		return
	}

	function validateFeedUrl() {
		console.log("validateFeedUrl: in")
		var text = feedUrlTextField.text
		const pattern = /^https?:\/\/([a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*|\d{1,3}(\.\d{1,3}){3})(:\d+)?(\/.*)?$/;
		if (!pattern.test(text)) {
			//% "'%1' is not a valid IP address."
			// qsTrId("ip_address_input_not_valid").arg(trimmed)
			return "Invalid URL"
		}

		return
	}
}