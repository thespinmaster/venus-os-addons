// HARD LINKED
import QtQuick 2

QtObject {
	id: root

	property alias traceEnabled: bridge.traceEnabled
	readonly property bool running: _operationName != "" || _finalizing_install
	readonly property string operationName: _operationName
	property string _operationName: ""
	property bool noAction: noActionSetting.value == 1
	property bool showCompact: showCompactSetting.value == 1
	property var outputLog: null
	property string _lastErrorLine: ""
	property var _completionCallback: undefined
	property var _connected: _connectedItem.value == 1
	readonly property string serviceUid: _connectedItem.opkgManagerServiceUid
	property bool _finalizing_install: false

	signal log(string line)

	function showToastNotification(level, message, duration) {
		//OVERRIDE
		console.log("Warning: showToastNotification not overriden" )
	}

	function tryPop(toPage) {
		//var _unused = toPage
		if (running && !_finalizing_install) {

			//% "Please wait for the operation to finish"
			root.showToastNotification(0, qsTrId("opkg_wait_for_opkg_operation_to_finish"), 2000)

			return false
		}
		return true
	}

	property VeQuickItemAdapter showCompactSetting: VeQuickItemAdapter {
		uid: systemSettingsServiceUid + "/Settings/OpkgManager/ShowCompact"
	}

	property VeQuickItemAdapter noActionSetting: VeQuickItemAdapter {
		uid: systemSettingsServiceUid + "/Settings/OpkgManager/NoAction"
	}

	property OpkgBridge bridge: OpkgBridge {
		id: bridge
		traceEnabled: true
	}

	property OpkgJsonReader dataReader: OpkgJsonReader {
		id: dataReader
	}

	property VeQuickItemAdapter _connectedItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Connected"
	}

	function cleanup() {
		bridge.cleanup()
	}

	function cancel() {
		if (bridge.running)
			bridge.stop()
	}

	function setOutputLog(logViewer) {
		outputLog = logViewer
		logViewer?.clear()
	}

	function snapshotObject(source) {
		return source ? JSON.parse(JSON.stringify(source)) : null
	}

	function _writeLog(line) {
		if (line=="::FINALIZING-INSTALL::") {
			_finalizing_install = true
			const Notification_Info=2
			//% "Finiazing install. The UI will restart shortly"
			line = qsTrId("opkg_finalize_install")
			showToastNotification(Notification_Info, line, 5000)
		}

		if (outputLog)
			outputLog.log(line)

		if (traceEnabled)
			console.log(line)

		log(line) // signal
	}

	function _notifyCompletion(result) {

		//var stack = (new Error()).stack
		//root._writeLog("_notifyCompletion:" + stack)

		var callback = root._completionCallback
		var lastError = root._lastErrorLine

		result.operationName = root._operationName
		root._operationName = ""
		root._completionCallback = undefined

		if (!result.success && !result.cancelled) {
			// var warnText="exitCode=" + result.exitCode + ",exitStatus=" + result.exitStatus
			var warnText = _lastErrorLine?.length
				? _lastErrorLine
				: result.error?.length
					? result.error
					: qsTr("Operation failed")
			root.showToastNotification(0, warnText, 3000)
		}

		callback?.(result)

	}

	function addFeed(feedName, url, completionCallback) {
		executeCommand(null,"feed", "add", [feedName, url], completionCallback)
	}

	function removeFeed(feedName, completionCallback) {
		executeCommand(null,"feed", "remove", [feedName], completionCallback)
	}
	function updateFeed(feedName, url, origFeedName, completionCallback) {
		executeCommand(null,"feed", "edit", [feedName, url, origFeedName], completionCallback)
	}

	function loadPackages(force, completionCallback) {
		var args = force ? ["force"] : undefined
		executeCommand("package load","packages", "update", args, completionCallback)
	}
	function loadFeeds(force, completionCallback) {
		var args = force ? ["force"] : undefined
		executeCommand("feed load","packages", "update", args, completionCallback)
	}

	function installPackage(packageName, completionCallback) {
		var args = _makePackageArgs(packageName)
		executeCommand(null,"package", "install", args, completionCallback)
	}

	function upgradePackage(packageName, completionCallback) {
		var args = _makePackageArgs(packageName)
		executeCommand(null,"package", "upgrade", args, completionCallback)
	}

	function removePackage(packageName, completionCallback) {
		const args = _makePackageArgs(packageName)
		executeCommand(null,"package", "remove", args, completionCallback)
	}

	function _makePackageArgs(packageName) {
		return root.noAction ? [packageName, "--noaction"] : [packageName]
	}


	function usbScan(completionCallback) {
		executeCommand(null, "device", "scan", [], completionCallback)
	}
	function bindDeviceToService(usbHash, port, devicePath, jsonUsbPropsObject, completionCallback) {
		//var reconnectArg = reconnect ? "true" : ""
		var strJsonUsbProps = JSON.stringify(jsonUsbPropsObject)
		executeCommand(null,"device", "bind", [usbHash, port, devicePath, strJsonUsbProps], completionCallback)
	}
	function checkDeviceServiceState(port, completionCallback) {
		//var reconnectArg = reconnect ? "true" : ""
		executeCommand(null,"device", "check-service-state", [port], completionCallback)
	}

	function detectDevice(serviceType, reconnect, completionCallback) {
		var reconnectArg = reconnect ? "true" : ""
		executeCommand(null,"device", "detect", [serviceType, reconnectArg], completionCallback)
	}

	function applyDevice(serviceType, port, usbProps, completionCallback) {
		executeCommand(null,"device", "apply", [serviceType, port, usbProps], completionCallback)
	}

	function removeDeviceEx(sid, devicePath, completionCallback) {
		executeCommand(null, "device", "remove", [sid, devicePath], completionCallback)
	}

	function removeDevice(sid, completionCallback) {
		executeCommand(null,"device", "remove", [sid], completionCallback)
	}

	function executeCommand(operationName, familyName, commandName, args, completionCallback) {
		var opName = operationName || familyName + " " + commandName

		var error
		if (!_connected) error = "Opkg Manager Service not running"
		if (!error && bridge.running) error = "Bridge already running"
		if (error) {
			var result = {success: false, error: error}
			root.showToastNotification(0,result.error, 3000)
			completionCallback?.(result)
			return
		}

		root._operationName = opName
 		root._completionCallback = (completionCallback && completionCallback.call) ? completionCallback : undefined

		bridge.start(familyName, commandName, ...(args || []))
	}

	function logError(error) {
		root._lastErrorLine = error
		root._writeLog(error)
	}

	property Connections bridgeConnections: Connections {
		target: bridge

		function onOutput(line) {
			root._writeLog(line)
		}

		function onError(error) {
			root.logError(error)
		}

		function onFinished(result) {
			console.log("onFinished in:" + root.operationName + ", exitCode:" + result.exitCode + ", exitStatus:" + result.exitStatus)

			var notifyCalled = false

			try {
				if (result.success) {
					if (root.operationName.startsWith("package ")) {
						dataReader.readAll("packages")
						return
					} else if (root.operationName.startsWith("feed ")) {
						console.log("dataReader.readAll:feeds")
						dataReader.readAll("feeds")
						return
					}
				}

				var data
				if (result.json?.length) {
					result.data = JSON.parse(result.json)
					delete result.json;
				}

				notifyCalled = true
				root._notifyCompletion(result)

			} catch (e) {
				root.logError("ERROR:onFinished: " + e)
				result.error = e
				result.success = false
				if (!notifyCalled)
					root._notifyCompletion(result)
			}
		}

	}

	property Connections readerConnections: Connections {
		target: dataReader

		function onJsonReady(jsonData, jsonText, name) {
			root._notifyCompletion({exitCode:0, exitStatus:0, success: true, data:jsonData})
		}

		function onJsonError(error, name) {
			root.logError(error)
			root._notifyCompletion({exitCode:1, exitStatus:0, success: false, error:error})
		}
	}
}