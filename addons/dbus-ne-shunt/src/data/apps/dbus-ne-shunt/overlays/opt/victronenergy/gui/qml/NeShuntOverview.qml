import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import "opkg-custom-service.js" as CustomService
import "color-utils.js" as ColorUtils

OpkgCustomOverviewPage {
  id: root
	source: "NeShuntOverview.qml"

  property string settingsPrefix: "com.victronenergy.settings/Settings/Devices/dbus_neshunt/"
  property MbStyle mbStyle: MbStyle {isCurrentItem: true}
	VBusItem { id: customNameItem; bind: Utils.path(bindPrefix, "/CustomName")}
  property string iconSuffix
  property string iconSuffixSelected

  VBusItem { id: customNameItem; bind: bindPrefix ? Utils.path(bindPrefix, "/CustomName") : undefined}
  VBusItem { id: internalLightItem; bind: bindPrefix ? Utils.path(bindPrefix, "/SwitchableOutput/InternalLights/State") : undefined }
  VBusItem { id: externalLightItem; bind: bindPrefix ? Utils.path(bindPrefix, "/SwitchableOutput/ExternalLights/State") : undefined }
  VBusItem { id: waterPumpItem; bind: bindPrefix ? Utils.path(bindPrefix, "/SwitchableOutput/WaterPump/State") : undefined }
  VBusItem { id: auxPowerItem; bind: bindPrefix ? Utils.path(bindPrefix, "/SwitchableOutput/Aux/State") : undefined }

  VBusItem { id: internalLightCustomNameItem; bind: bindPrefix ? Utils.path(bindPrefix, "/SwitchableOutput/InternalLights/Settings/CustomName") : undefined }
  VBusItem { id: externalLightCustomNameItem; bind: bindPrefix ? Utils.path(bindPrefix, "/SwitchableOutput/ExternalLights/Settings/CustomName") : undefined }
  VBusItem { id: waterPumpCustomNameItem; bind: bindPrefix ? Utils.path(bindPrefix, "/SwitchableOutput/WaterPump/Settings/CustomName") : undefined }
  VBusItem { id: auxPowerCustomNameItem; bind: bindPrefix ? Utils.path(bindPrefix, "/SwitchableOutput/Aux/Settings/CustomName") : undefined }

	Connections {
		target: mbStyle

    property color colorHelper

		function onTextColorChanged() {root.iconSuffix = getIconSuffix(mbStyle.textColor)}
    function onTextColorSelectedChanged() {root.iconSuffixSelected = getIconSuffix(mbStyle.textColorSelected)}
    function getIconSuffix(clr) {
      colorHelper = clr
      return ColorUtils.isDarkColor(colorHelper) ? "-dark" : "-light"
    }

    Component.onCompleted: {
      onTextColorChanged()
      onTextColorSelectedChanged()
    }
  }

  // Header
  Text {
      id: header
      text: customNameItem.value || qsTr("Ne-Shunt")
      color: mbStyle.textColor
      font.bold: true
      font.pixelSize: 14
      //font.bold: true
      anchors {
        top: parent.top
        left: parent.left
        topMargin: 4
        horizontalCenter: parent.horizontalCenter
      }
      horizontalAlignment: Text.AlignHCenter
  }

  // Centered row of 4 LargeRoundButton instances
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    spacing: 20

    LargeRoundButton {
      text: internalLightCustomNameItem.value && internalLightCustomNameItem.length > 0 || qsTr("Indoor Lights")
      checked: internalLightItem.valid && internalLightItem.value != 0
      onCheckedChanged: { internalLightItem.setValue(checked ? 1 : 0)}
      iconId: Utils.path("ne-shunt-inside-light", checked ? root.iconSuffixSelected : root.iconSuffix)
    }
    LargeRoundButton {
      text: externalLightCustomNameItem.value && externalLightCustomNameItem.length > 0 || qsTr("Outdoor Light")
      checked: externalLightItem.valid && externalLightItem.value != 0
      onCheckedChanged: { externalLightItem.setValue(checked ? 1 : 0)}
      iconId:  Utils.path("ne-shunt-outside-light", checked ? root.iconSuffixSelected : root.iconSuffix)
    }
    LargeRoundButton {
      text: waterPumpCustomNameItem.value && waterPumpCustomNameItem.length > 0 || qsTr("Water Pump")
      checked: waterPumpItem.valid && waterPumpItem.value != 0

      onCheckedChanged: { waterPumpItem.setValue(checked ? 1 : 0)}
      iconId: Utils.path("ne-shunt-water-pump", checked ? root.iconSuffixSelected : root.iconSuffix)
    }
    LargeRoundButton {
      text: auxPowerCustomNameItem.value && auxPowerCustomNameItem.length > 0 || qsTr("Aux Power")
      checked: auxPowerItem.valid && auxPowerItem.value != 0
      onCheckedChanged: { auxPowerItem.setValue(checked ? 1 : 0)}
      iconId: Utils.path("ne-shunt-aux-power", checked ? root.iconSuffixSelected : root.iconSuffix)
      longPressDuration: 3000
    }
  }

  Component.onCompleted: discoverNeShunt()

	Connections {
		target: DBusServices
		function onDbusServiceFound(service) { tryAddService(service) }
	}

	function tryAddService(service) {

    if (!bindPrefix) {
      if (service.type === DBusService.DBUS_SERVICE_TEMPERATURE_SENSOR &&
          service.name.includes(".dbus_ne_shunt_sid_")) {
        bindPrefix = service.name
      }
    }
	}

	function discoverNeShunt() {
		for (var i = 0; i < DBusServices.count; i++) {
      tryAddService(DBusServices.at(i))
    }
	}

}