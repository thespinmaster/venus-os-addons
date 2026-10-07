import QtQuick 2

MbSwitch {
  bind: "com.victronenergy.settings/Settings/OpkgManager/CustomMenus/PageMain/PageSettings"
  name: qsTr("Move settings to top")
  valueFalse: ""
  valueTrue: "^"
	x: -2000
}
