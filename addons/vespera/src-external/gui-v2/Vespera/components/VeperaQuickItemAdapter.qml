import Victron.VenusOS

VeQuickItem {
	readonly property int version: 2

	function serviceUidFromName(string, instanceId) {
		return BackendConnection.serviceUidFromName(string, instanceId)
	}

	readonly property string vesperaServiceUid: serviceUidFromName("com.victronenergy.vespera", 0)
	readonly property string systemSettingsServiceUid: Global.systemSettings.serviceUid

}