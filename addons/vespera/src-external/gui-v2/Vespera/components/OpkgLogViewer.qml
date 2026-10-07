import QtQuick 2
import Victron.VenusOS

OpkgLogViewerBase {
	id: root

	fontSize: Theme.font_size_body1
	defaultLineColor: Theme.color_font_primary
	warningLineColor: Theme.color_warning
	errorLineColor: Theme.color_red
	successLineColor: Theme.color_green
	backgroundColor: Theme.colorScheme === Theme.Dark ? Theme.color_gray1 : Theme.color_listItem_background
}
