// SYM LINKED
import QtQuick 2

QtObject {
	id: root

	property bool running: false
	property bool stopping: false
	property bool traceEnabled: false
	property int _cancelRequestSeq: 0

	property int _lastStdoutSeq: 0
	property int _lastFinishedSeq: 0

	// When stop() is called, snapshot the seq values at that moment.
	// Any output events with seq > these values are in-flight MQTT
	// messages that were already published before the service saw our cancel;
	// we discard them immediately rather than waiting for the round trip.
	property bool _isCancelling: false
	property int _cancelStdoutSeq: 0

	signal output(string line)
	signal error(string line)
	signal finished(var result)

	function _toInt(value) {
		var n = Number(value)
		if (!isFinite(n)) {
			return 0
		}
		return Math.floor(n)
	}

	function _toString(value) {
		if (value === undefined || value === null) {
			return ""
		}
		return String(value)
	}

	function _trace(line, isError) {
		if (!traceEnabled) {
			return
		}
		if (isError) {
			console.error("[OpkgBridge] " + line)
		} else {
			console.log("[OpkgBridge] " + line)
		}
	}

	function _snapshotSeqState() {
		_lastStdoutSeq = _toInt(stdoutSeqItem.value)
		_lastFinishedSeq = _toInt(finishedSeqItem.value)
	}

	function waitForFinished(msecs) {
		var _unused = msecs
		if (_unused < 0) {
			return !running
		}
		return !running
	}

	function start(command, action) {

		if (stopping || running) {
			_trace("start() ignored while busy", false)
			return
		}

		if (!command || !action) {
			_trace("start(): invalid args", true)
			error("Invalid args: expected '<command> <action> [args...]'")
			return
		}

		_snapshotSeqState()

		var inputArgs = Array.prototype.slice.call(arguments)
		while (inputArgs.length > 2) {
			var lastArg = inputArgs[inputArgs.length - 1]
			if (lastArg !== null && lastArg !== undefined)
				break
			inputArgs.pop()
		}

		var argsJson = JSON.stringify(inputArgs)
		argsJsonItem.setValue(argsJson)
		resultJsonItem.setValue("") // clear any result

		var startValue = _toInt(startItem.value)
		startItem.setValue(startValue + 1)
		_trace("start(): args=" + argsJson, false)
	}

	function stop() {
		if (stopping || !running) {
			return
		}

		// Snapshot seq values now so we can discard in-flight messages that
		// were already published to MQTT before the service sees the cancel.
		_isCancelling = true
		_cancelStdoutSeq = _toInt(stdoutSeqItem.value)

		_cancelRequestSeq = _cancelRequestSeq + 1
		cancelItem.setValue(_cancelRequestSeq)
		_trace("stop(): cancel requested seqStdout=" + _cancelStdoutSeq, false)
		root.output("Cancelling...")
	}

	function cleanup() {
		stop()
	}

	function _isOperationActive() {
		return root.running || root.stopping
	}

	function _acceptEventSeq(seq, seqPropertyName) {
		if (seq === root[seqPropertyName])
			return false

		root[seqPropertyName] = seq
		return true
	}

	property VeQuickItemAdapter stdoutSeqItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Event/StdoutSeq"
		onValueChanged: {
			var seq = root._toInt(root.stdoutSeqItem.value)
			if (!root._acceptEventSeq(seq, "_lastStdoutSeq")) {
				return
			}
			if (root._isCancelling && seq > root._cancelStdoutSeq) {
				return
			}

			var line = root._toString(root.stdoutLineItem.value)
			if (line.length > 0) {
				root.output(line)
			}
		}
	}

	property VeQuickItemAdapter finishedSeqItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Event/FinishedSeq"
		onValueChanged: {
			var seq = root._toInt(root.finishedSeqItem.value)
			if (!root._acceptEventSeq(seq, "_lastFinishedSeq")) {
				return
			}

			var exitCode = root._toInt(root.exitCodeItem.value)
			var exitStatus = root._toInt(root.exitStatusItem.value)
			if (root._isCancelling) {
				root.output("Cancelled")
			}
			var cancelled = root._isCancelling
			root._isCancelling = false

			if (exitCode !== 0) {
				var msg = root._toString(root.resultErrorItem.value)
				if (msg.length > 0) {
					root.error(msg)
				}
			}

			var result = {
				exitCode: exitCode,
				exitStatus: exitStatus,
				cancelled: cancelled,
				success: exitCode == 0 && exitStatus == 0,
				json: root.resultJsonItem.value
			}

			root.finished(result)
		}
	}

	property VeQuickItemAdapter argsJsonItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Request/ArgsJson"
	}

	property VeQuickItemAdapter startItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Request/Start"
	}

	property VeQuickItemAdapter cancelItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Request/Cancel"
	}

	property VeQuickItemAdapter statusItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/State/Status"
		onValueChanged: {
			var value = root._toInt(root.statusItem.value)
			root.running = value !== 0
			root.stopping = (value & 0x2) == 0x2
		}
	}

	property VeQuickItemAdapter stdoutLineItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Event/StdoutLine"
	}

	property VeQuickItemAdapter exitCodeItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Result/ExitCode"
	}

	property VeQuickItemAdapter exitStatusItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Result/ExitStatus"
	}

	property VeQuickItemAdapter resultErrorItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Result/Error"
	}

	property VeQuickItemAdapter resultJsonItem: VeQuickItemAdapter {
		uid: opkgManagerServiceUid + "/Result/Json"
	}

	Component.onCompleted: {
		var status = _toInt(statusItem.value)
		running = status !== 0
		stopping = (status & 0x2) == 0x2
		_cancelRequestSeq = _toInt(cancelItem.value)
		_snapshotSeqState()
	}
}
