#!/usr/bin/env python3

"""
A class to put a simple service on the dbus, according to victron standards, with constantly updating
paths. See example usage below. It is used to generate dummy data for other processes that rely on the
dbus. See files in dbus_vebus_to_pvinverter/test and dbus_vrm/test for other usage examples.

To change a value while testing, without stopping your dummy script and changing its initial value, write
to the dummy data via the dbus. See example.

https://github.com/victronenergy/dbus_vebus_to_pvinverter/tree/master/test
"""

from gi.repository import GLib
import platform
import logging
import os
import dbus

from dbus_connection import dbusconnection
from ext.vedbus import VeDbusService
from ext.vedbus import VeDbusItemImport

class dbus_base_service(object):

	_dbusservice = None
	_bus = None

	# Create the mandatory objects
	def unregister(self):
		"""
		Unregister the dbus service.
		"""
		if self._dbusservice:
			self._dbusservice.__del__()
			self._dbusservice = None
			self._bus = None
			logging.debug("Unregistered %s" % (self._dbusservice))
		else:
			logging.debug("No dbus service to unregister")


	def _registerCore(self, connection:str,
                   deviceInstance: int,
                   serviceName:str,
                   productId:int,
                   productName:str,
									 productVersion:str,
                   firmwareVersion:str,
                   hardwareVersion:str,
                   paths, onValueChanged = None):

		logging.debug("_registerCore in")

		self._bus = dbusconnection()
		self._dbusservice = VeDbusService(serviceName, bus=self._bus, register=False)

		self._paths = paths

		self._dbusservice.add_path('/Mgmt/ProcessName', __file__)
		self._dbusservice.add_path('/Mgmt/ProcessVersion', platform.python_version())
		self._dbusservice.add_path('/Mgmt/Connection', connection)

		# Create rest of the mandatory objects
		self._dbusservice.add_path('/DeviceInstance', deviceInstance)
		self._dbusservice.add_path('/ProductId', productId)
		self._dbusservice.add_path('/ProductName', productName)
		self._dbusservice.add_path('/ProductVersion', productVersion)
		self._dbusservice.add_path('/Connected', 1)

		if (firmwareVersion):
				self._dbusservice.add_path('/FirmwareVersion', firmwareVersion)
		if (hardwareVersion):
				self._dbusservice.add_path('/HardwareVersion', hardwareVersion)

		for path, settings in self._paths.items():
			self._dbusservice.add_path(
				path,
				value = settings["initial"],
				writeable = settings["writable"],
				onchangecallback = onValueChanged)

		self._dbusservice.register()


	def get_value(self, path):
		"""
		Get the value of a path.
		"""
		if (self._dbusservice == None):
			return None

		return self._dbusservice[path]


	def set_value(self, path, value):
		"""
		Set the value of a path.
		"""
		if (self._dbusservice == None):
			return False

		with self._dbusservice as s:
			s[path] = value
			logging.debug("Set %s to %s" % (path, value))
		return True

	def set_dbus_value(self, service,path,value):
		bus = self._bus
		if bus is None:
			logging.error("Cannot inject notification: no dbus connection found")
			return False

		obj = bus.get_object(service, path)
		iface = dbus.Interface(obj, "com.victronenergy.BusItem")
		iface.SetValue(value, timeout=2)

	def inject_notification(self, title: str, message: str, level: str = "alarm"):

		title = (title or "")[:100]
		message = (message or "")[:500]
		payload = f"{level}\t{title}\t{message}"

		try:
			if not (self.set_dbus_value("com.victronenergy.platform","/Notifications/Inject",dbus.String(payload))):
				return False
			if not (self.set_dbus_value("com.victronenergy.platform","/Notifications/Alarm",dbus.Boolean(True))):
				return False

			logging.debug("Injected notification level=%s title=%s", level, title)
			return True
		except Exception:
			logging.exception("Failed to inject notification")
			return False

	@property
	def serviceName(self):
		if (self._dbusservice == None):
			return None
		return self._dbusservice.name

	@staticmethod
	def serviceNameBuilder(className:str, serviceIdentifier:str) -> str:
		return "com.victronenergy.{}.{}".format(
			className, serviceIdentifier)
