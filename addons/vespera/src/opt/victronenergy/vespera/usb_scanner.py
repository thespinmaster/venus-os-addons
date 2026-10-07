import json
import logging

import dbus
from gi.repository import GLib  # type: ignore
from ext.vedbus import VeDbusService
from command_state import CommandState

log = logging.getLogger(__name__)

class UsbScanner:
	"""Parses DISCOVERED tab lines emitted by a device scan and publishes /Discovered/* D-Bus paths."""

	_dbusservice: VeDbusService

	def __init__(self, dbusservice):
		self._dbusservice = dbusservice
		self._claimed_sids = set()

	def handle_line(self, state: CommandState, line: str) -> bool:
		"""Return True if the line was a DEVICE:[ACTION] record and was consumed."""
		log.info(line)
		if state.operation_name not in ("device scan", "device bind", "device apply"):
				log.info("exiting handle_line:" + state.operation_name)
				return False

		if line.startswith("DEVICE:DISCOVERED\t"):
			GLib.idle_add(self._publish_discovered_device, line)
			return True

		if line.startswith("DEVICE:CLAIMED\t"):
				log.info("adding _device_claimed to stack")
				GLib.idle_add(self._device_claimed, line)
				return True

		return False

	def _device_claimed(self, line):
		"""Delete all the keys with the /Discovered/[sid].
				line is in the form DEVICE:CLAIMED[tab][sid]"
				Called via GLib.idle_add; return False to run once and then be removed.
		"""
		log.info("_device_claimed in")
		parts = line.rstrip().split("\t", 1)
		if len(parts) < 2 or not parts[1].strip():
			log.info("_device_claimed out error")
			raise ValueError("Invalid DEVICE:CLAIMED line")

		sid = parts[1].strip()
		self._claimed_sids.add(sid)
		prefix = f"/Discovered/sid_{sid}/"
		log.info("_device_claimed deleting subtree:" + prefix)

		deleted = False
		for p in list(self._dbusservice._dbusobjects.keys()):
			if isinstance(p, str) and p.startswith(prefix) and p in self._dbusservice:
				log.info("_device_claimed invalidating key:" + p)
				self._dbusservice[p] = None
				deleted = True

		if not deleted:
			log.warning("_device_claimed subtree not found: " + prefix)
		return False

	def clear_discovered_devices(self):
		"""Remove all /Discovered/* paths from the D-Bus service."""
		self._claimed_sids.clear()
		self.__delete_path("/Discovered/")

	def __delete_path(self, path):
		"""Delete all the keys under the provided path* paths from the D-Bus service."""
		log.info("in __delete_path: %s", path)
		paths_to_delete = []
		try:
			for p in list(self._dbusservice._dbusobjects.keys()):
				if isinstance(p, str) and p.startswith(path):
					log.info("__delete_path:FOUND %s", p)
					paths_to_delete.append(p)
		except Exception as e:
			log.exception(f"Failed to enumerate /Discovered subtree for cleanup: {e}")

		for p in paths_to_delete:
			if p in self._dbusservice:
				log.info("__delete_path:Invalidating:%s", p)
				self._dbusservice[p] = None

	def _publish_discovered_device(self, line: str):
		# Called via GLib.idle_add; return False to run once and then be removed.

		jsonPayload = _discovered_to_json(line)
		sid = str(jsonPayload.get("hash", "")).strip()
		if not sid:
			log.warning("_publish_discovered_device skipping invalid sid for line: %s", line)
			return False
		if sid in self._claimed_sids:
			log.info("_publish_discovered_device skipping claimed sid:%s", sid)
			return False

		path = f"/Discovered/sid_{sid}/Port"
		if path not in self._dbusservice:
				self._dbusservice.add_path(path, "", valuetype = dbus.String)
		self._dbusservice[path ] = jsonPayload.get("port", "")

		path = f"/Discovered/sid_{sid}/UsbProps"
		if path not in self._dbusservice:
			self._dbusservice.add_path(path, "", valuetype = dbus.String)
		self._dbusservice[path] = json.dumps(jsonPayload.get("usbProps"))

		return False

def _format_name(key: str) -> str:
    if key.startswith("ID_"):
        key = key[3:]
    if key.endswith("_ID"):
        key = key[:-3]

    return key.replace("_", " ").title()

def _discovered_to_json(line: str) :
    parts = line.rstrip().split("\t")

    if len(parts) < 4:
        raise ValueError("Invalid DEVICE:DISCOVERED line")

    result = {
        "hash": parts[1],
				"port": parts[2],
        "usbProps": []
    }

    # Read all properties
    raw = {}
    for item in parts[3].split(","):
        if "=" in item:
            key, value = item.split("=", 1)
            if value == "":
              continue
            raw[key] = value

    # Build usbProps
    for key, value in raw.items():
        if key.endswith("_ID"):
            base = key[:-3]
            if raw.get(base):
                continue

        result["usbProps"].append({
            "name": _format_name(key),
            "value": value
        })

    return result