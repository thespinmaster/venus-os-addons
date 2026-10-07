/*
** Copyright (C) 2025 Victron Energy B.V.
** See LICENSE.txt for license information.
*/

import QtQuick
import Victron.VenusOS
import QtQuick.Controls 2.12

SwipeViewPage {
	id: root
	readonly property bool pluginReady: !GuiPluginLoader.busy && GuiPluginLoader.plugin("Vespera").name === "Vespera"

	//% "Inetbox"
	title: "Motorhome" // qsTrId("nav_boat")
	iconSource: "qrc:/Inetbox/image_motorhome.svg"
	url: "qrc:/Inetbox/Motorhome.qml"
	fullScreenWhenIdle: true
	topLeftButton: VenusOS.StatusBar_LeftButton_ControlsInactive
	property var device

	VeQuickItem {
		id: customPage
		uid: Global.systemSettings.serviceUid + "/Settings/Gui/BoatTestPage"
    function onValueChanged() {
		}
	}

	Component.onCompleted: {
		console.log("root.pluginReady:" + root.pluginReady)
		addDevice()
	}


FilteredDeviceModel {
		id: nonSystemLoadDevices
		serviceTypes: ["inetbox"]
		onRowsRemoved: function() {
			root.addDevice()
		}
		onRowsInserted: function() {
			root.addDevice()
		}
	}

	function addDevice() {
		console.log("addDevice in")
		var d
		for (var i = 0; i < nonSystemLoadDevices.count; i++) {
			d = nonSystemLoadDevices.deviceAt(i)
			if (d.connected)
				break
		}
		if (d)
			console.log("INETBOX-DEVICE FOUND:" + d)
		deviceLoader.device = d
	}

	function deviceUid(suffix) {
		return deviceServiceUid ? (deviceServiceUid + suffix) : ""
	}



	Loader {
		id: deviceLoader
		property var device

		anchors.fill: parent

		active: root.pluginReady
		source: active ? (customPage.valid && customPage.value !== undefined
				? customPage.value
				: (Theme.screenSize === Theme.Portrait
						? "qrc:/Inetbox/InetboxOverviewPage_Portrait.qml"
						: "qrc:/Inetbox/InetboxOverviewPage_Landscape.qml"))
			: ""

	}

}
