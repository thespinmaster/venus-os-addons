import QtQuick 2
import Theming 1.0

QtObject {
	id: root
 
	Component.onCompleted: {
		if (connection) {
			connection.color = Themer.windowBackgroundColor
		}
		if (ball?.border) {
			ball.border.color = Themer.windowBackgroundColor
		}
	}
}
