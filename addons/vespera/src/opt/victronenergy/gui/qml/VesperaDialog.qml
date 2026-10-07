import QtQuick 2

Rectangle {
	id: root
	color: "#4f4f4f"
	radius: 8
	//border.width: root.mbStyle.itemHeight
	//border.color: '#854f4f4f'
	border.width: 6
	border.color:  '#b90c7fe3'
	smooth: true
	visible: false

	signal buttonClicked(string id)

	property alias icon: _icon.iconId
	property string message
	property MbStyle mbStyle: MbStyle {isCurrentItem: true}
	property var buttonsModel
	//property var buttonsModel: [{id:"cancel",text:"Cancel"},{id:"ok",text:"Ok",enabled:false}]
	property var messageTextAlignment: Text.AlignLeft
	property var closeOnButtonClick: true
	property var _callback

	function show(message, icon, callback) {
		root.message = message == undefined ? "" : message
		root.icon = icon == undefined ? "" : icon
		_callback = callback
		root.visible = true
	}
	function close() {
		visible = false
		message=""
	}

	anchors {
		fill: parent
		margins: root.mbStyle.itemHeight /2
	}

	Rectangle {
		radius: 8
		color: '#4f4f4f'
		anchors {
			margins: root.mbStyle.marginDefault
			fill: parent
		}

		MbIcon {
			id: _icon
			anchors {
				top: parent.top
				topMargin: root.mbStyle.marginDefault
				left: parent.left; leftMargin: iconId == "" ? 0 : root.mbStyle.marginDefault
			}
		}

		Text {
			id: _message
			text: message
			font.pixelSize: root.mbStyle.fontPixelSize
			horizontalAlignment: messageTextAlignment
			wrapMode: Text.WrapAtWordBoundaryOrAnywhere
			color: root.mbStyle.textColor
			anchors {
				left: _icon.right; leftMargin: root.mbStyle.marginDefault
				top: parent.top; topMargin: _icon.iconId == "" ? root.mbStyle.marginDefault :  root.mbStyle.marginDefault *2
				right:parent.right; rightMargin: root.mbStyle.marginDefault
				bottom: buttonsRow.top; bottomMargin: root.mbStyle.marginDefault
			}
		}

		Row {
			id:buttonsRow
			layoutDirection: Qt.RightToLeft
			anchors {
				bottom: parent.bottom
				right: parent.right
				margins:4
			}
			spacing: 8
			Repeater {
				model: root.buttonsModel
				delegate: buttonFactory
			}
		}
	}

	Component {
		id: buttonFactory
		Rectangle {
			id: button
			width: 100
			radius: 4
			height: root.mbStyle.itemHeight
			border.width:1
			border.color: root.mbStyle.backgroundColor
			color: '#787878'

			Text {
				text: modelData.text
				opacity: modelData.enabled || modelData.enabled == undefined
					? root.mbStyle.opacityEnabled
					: root.mbStyle.opacityDisabled
				color: root.mbStyle.textColor
				font.pixelSize: root.mbStyle.fontPixelSize
				anchors.fill: parent
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
			anchors {
				margins:14
			}
			MouseArea {
				width: button.width
				height: button.height
				onClicked: {
					if (modelData.enabled || modelData.enabled == undefined) {
						if (_callback)
							_callback(modelData.id)

						buttonClicked(modelData.id)
						if (root.closeOnButtonClick)
							close()
					}
				}
			}
		}
	}
}
