import com.victron.velib 1.0

VeQuickItem {

	function serviceUidFromName(string) {
		return "dbus/" + string
	}

	readonly property string opkgManagerServiceUid: "dbus/com.victronenergy.opkgmanager"
	readonly property string systemSettingsServiceUid: "dbus/com.victronenergy.settings"

}