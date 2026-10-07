#!/usr/bin/env python3

"""
A class to put a simple service on the dbus, according to victron standards, with constantly updating
paths. See example usage below. It is used to generate dummy data for other processes that rely on the
dbus. See files in dbus_vebus_to_pvinverter/test and dbus_vrm/test for other usage examples.

To change a value while testing, without stopping your dummy script and changing its initial value, write
to the dummy data via the dbus. See example.

https://github.com/victronenergy/dbus_vebus_to_pvinverter/tree/master/test
"""
from gi.repository import GLib # type: ignore
import platform
import logging
import random

from ext.vedbus import VeDbusService
from ext.settingsdevice import SettingsDevice
from dbus_connection import dbusconnection
from serial_port_reader import SerialPortReader

PRODUCT_NAME = "test device service"
PRODUCT_ID = 0
SAFE_PRODUCT_NAME="test_device_service"
DEVICE_KEY_NAME="TestDevice"
DEFAULT_DEVICE_INSTANCE=764

class DbusTestDeviceService(object):

		_inUpdate = False
		_settingsPath = None
		_servicePaths = {}
		_sid : str
		_settings : SettingsDevice
		_temperatures = (12,18,29)

		def __init__(self, serialPort, sid):

				self._sid = sid

				deviceClassName = "temperature"
				serviceIdentifier = "sid_" + sid

				# Keep initialize_settings before serviceName, as deviceInstance may use a
				# an optional ClassAndVrmInstance value

				service_name = "com.victronenergy.{}.{}".format(
					deviceClassName, serviceIdentifier)

				self.initialize_settings(deviceClassName, service_name)

				self._dbusservice = VeDbusService(service_name, register=False)

				logging.debug("%s /Device = %s" % (service_name, sid))

				# Create the management objects, as specified in the ccgx dbus-api document
				self._dbusservice.add_path('/Mgmt/ProcessName', __file__)
				self._dbusservice.add_path('/Mgmt/ProcessVersion', 'Unkown version, and running on Python ' + platform.python_version())
				self._dbusservice.add_path('/Mgmt/Connection', "usb")

				# Create the mandatory objects
				self._dbusservice.add_path('/DeviceInstance', sid)
				self._dbusservice.add_path('/ProductId', PRODUCT_ID)
				self._dbusservice.add_path('/ProductName', PRODUCT_NAME)
				self._dbusservice.add_path('/FirmwareVersion', 1)
				self._dbusservice.add_path('/HardwareVersion', 1.1)
				self._dbusservice.add_path('/Connected', 1)

				self.initialize_service_paths()

				self._dbusservice.register()

				self._serial_device = SerialPortReader(serialPort)


		def initialize_service_paths(self):

				self._dbusservice.add_path(
						'/CustomName', "", writeable=True,
						onchangecallback=self._handle_service_value_changed)
				self._dbusservice.add_path(
						'/Temperature', 5, writeable=True,
						onchangecallback=self._handle_service_value_changed)

		def initialize_settings(self, deviceClassName: str, service_name:str ):
				settingsPath = f'/Settings/Devices/sid_{self._sid}'

				self._settingsPath = settingsPath

				self._settings = SettingsDevice(
			bus = dbusconnection(),
			supportedSettings = {
				'class_and_vrm_instance' : [f'{settingsPath}/ClassAndVrmInstance',
				f"{deviceClassName}:{DEFAULT_DEVICE_INSTANCE}", 0, 0],
 				#'show_fresh_water_tank': [f'{settingsPath}/ShowFreshWaterTank', 1, 0, 1],
				'/Sid' : [f'{self._settingsPath}/Sid', self._sid, 0, 0],
				'/ProductName' : [f'{self._settingsPath}/ProductName', PRODUCT_NAME, "", ""],
				'/ServiceName' : [f'{self._settingsPath}/ServiceName', service_name, "", ""],
				'/CustomName' : [f'{self._settingsPath}/CustomName', "", "", ""],
				'/DeviceKey' : [f'{self._settingsPath}/DeviceKey', DEVICE_KEY_NAME, "", ""]

				},
			eventCallback = self._handle_changed_setting)

		def _handle_changed_setting(self, setting, oldvalue, newvalue):
				logging.debug('setting changed, setting: %s, old: %s, new: %s' % (setting, oldvalue, newvalue))
				return True

		def _update(self):
				self._servicePaths['/Temperature'] = random.randint(4, 30)

				if self._serial_device:
						data = self._serial_device.read_data()
						if data != "":
								print(data)

				return True

		def _handle_service_value_changed(self, path, value):
				logging.debug("someone else updated service value %s to %s" % (path, value))
				return True # accept the change

		def close(self):
				if self._serial_device:
						self._serial_device.close()
						self._serial_device = None
