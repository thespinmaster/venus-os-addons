import sys
import os
import logging
import globals
from typing import Optional

sys.path.append(os.path.join(os.path.dirname(__file__), 'ext'))
sys.path.append(os.path.join(os.path.dirname(__file__), 'serial_service'))
sys.path.append(os.path.join(os.path.dirname(__file__), 'dbus_services'))

from dbus_services.switch_service import switch_service
from dbus_services.tank_service import tank_service
from dbus_services.battery_service import battery_service
from dbus_services.dbus_constants import dbus_constants
from dbus_services.dbus_connection import dbusconnection
from ext.settingsdevice import SettingsDevice  # available in the velib_python repository

from serial_service.ne_shunt_serial_service import ne_shunt_serial_service
from serial_service.ne_shunt_data import ne_shunt_data

############################################
# manages the reading and writing of data
# between the dbus and the serial device (ne-shunt)
############################################
class ne_shunt_services_controller:

	_serialService : Optional[ne_shunt_serial_service] = None
	_settings : SettingsDevice
	_curData : Optional[ne_shunt_data] = None
	_serial_port : str
	_inUpdate = False
	_settingsPath = None
	_lastData : str = ""
	_reset = False
	_readonly = False
	_cancelled = False
	_sid : str

	############################################
	# constructor
	# serial port is passed from the SerialStarter
	# service. i.e. /dev/ttyACM0
	############################################
	def __init__(self, serialPort, sid, readonly):
		self._serial_port = serialPort
		self._sid = sid
		self._readonly = readonly

	def close(self):
		self._cancelled = True

	############################################
	# Starts and stops the serial service as
	# required
	############################################
	def _start_stop_serial_service(self):
		logging.debug('_start_stop_serial_service')

		#state 0 (nothing running ... so close)
		if (self._serialService and len(self._services) == 0):
			self._serialService.close()
			self._serialService = None

		if (self._serialService == None and len(self._services) > 0):
			self._serialService = ne_shunt_serial_service(self._serial_port, self._readonly)

	############################################
	# Occurs when the a device setting value is
	# changed such as ShowControls
	############################################
	def _handle_changed_setting(self, setting, oldvalue, newvalue):
		logging.debug('setting changed, setting: %s, old: %s, new: %s' % (setting, oldvalue, newvalue))

		self._start_stop_services(setting, newvalue)
		return True

	############################################
	# Initializes the dbus device settings
	# Needs custom UI
	############################################
	def _initializeSettings(self):

		logging.debug("Initializing settings")

		# unique path used to generate unique ClassAndVrmInstance value
		# see https://github.com/victronenergy/localsettings#using-addsetting-to-allocate-a-vrm-device-instance
		#portName = os.path.basename(self._serial_port)
		settingsPath = f'/Settings/Devices/sid_{self._sid}'

		self._settings = SettingsDevice(
			bus = dbusconnection(),
			supportedSettings = {
# default custom device settings start
				'/Sid': [f'{settingsPath}/Sid', self._sid, 0, 0],
				'/Sid2' : [f'{self._settingsPath}/Sid2', self._sid, 0, 0],
				'/ProductName' : [f'{self._settingsPath}/ProductName', dbus_constants.PRODUCT_NAME, "", ""],
				'/ServiceName' : [f'{self._settingsPath}/ServiceName', "", "", ""],
				'/CustomName' : [f'{self._settingsPath}/CustomName', "", "", ""],
				'/DeviceKey' : [f'{self._settingsPath}/DeviceKey', dbus_constants.DEVICE_KEY_NAME, "", ""],
# default custom device settings end

				'/ShowFreshWaterTank': [f'{settingsPath}/ShowFreshWaterTank', 1, 0, 1],
				'/ShowGreyWasteTank': [f'{settingsPath}/ShowGreyWasteTank', 1, 0, 1],  # When empty, default path will be used.
				'/ShowGreyWasteTank2': [f'{settingsPath}/ShowGreyWasteTank2', 1, 0, 1],
				'/FreshWaterTank/ClassAndVrmInstance' : [f'{settingsPath}/FreshWaterTank/ClassAndVrmInstance',
													f"{dbus_constants.SERVICE_TYPE_TANK}:{dbus_constants.DEFAULT_DEVICE_INSTANCE}", 0, 0],
				'/GreyWasteTank/ClassAndVrmInstance' : [f'{settingsPath}/GreyWasteTank/ClassAndVrmInstance',
													f"{dbus_constants.SERVICE_TYPE_TANK}:{dbus_constants.DEFAULT_DEVICE_INSTANCE}", 0, 0],
				'/GreyWasteTank2/ClassAndVrmInstance' : [f'{settingsPath}/GreyWasteTank2/ClassAndVrmInstance',
													f"{dbus_constants.SERVICE_TYPE_TANK}:{dbus_constants.DEFAULT_DEVICE_INSTANCE}", 0, 0],
				'/CabBattery/ClassAndVrmInstance' : [f'{settingsPath}/CabBattery/ClassAndVrmInstance',
													f"{dbus_constants.SERVICE_TYPE_BATTERY}:{dbus_constants.DEFAULT_DEVICE_INSTANCE}", 0, 0],
				'/LeisureBattery/ClassAndVrmInstance' : [f'{settingsPath}/LeisureBattery/ClassAndVrmInstance',
													f"{dbus_constants.SERVICE_TYPE_BATTERY}:{dbus_constants.DEFAULT_DEVICE_INSTANCE}", 0, 0],
				'/Switches/ClassAndVrmInstance' : [f'{settingsPath}/Switches/ClassAndVrmInstance',
													f"{dbus_constants.SERVICE_TYPE_SWITCH}:{dbus_constants.DEFAULT_DEVICE_INSTANCE}", 0, 0]
				},
			eventCallback = self._handle_changed_setting)

	############################################
	# Occurs when a switch is toggled in the UI
	############################################
	def _dbus_switch_value_changed(self, path, newvalue):

		logging.info('dbus value changed, path: %s, newvalue: %s' % (path, newvalue))

		if (self._serialService == None or self._curData == None):
			return False


		if (path == '/SwitchableOutput/ExternalLights/State'):
			self._try_toggle_serial_switch_value("external_lights", newvalue)
		elif (path == "/SwitchableOutput/InternalLights/State"):
			self._try_toggle_serial_switch_value("internal_lights", newvalue)
		elif (path == "/SwitchableOutput/WaterPump/State" ):
			self._try_toggle_serial_switch_value("water_pump", newvalue)
		elif (path == "/SwitchableOutput/Aux/State" ):
			self._try_toggle_serial_switch_value("aux", newvalue)

		return True

	############################################
	# Occurs when a battery value has chnaged the UI
	############################################
	def _dbus_cab_battery_value_changed(self, path, newvalue):
		return self._dbus_battery_value_changed("cab_battery", path, newvalue)

	def _dbus_leisure_battery_value_changed(self, path, newvalue):
		return self._dbus_battery_value_changed("leisure_battery", path, newvalue)

	def _dbus_battery_value_changed(self,serviceName, path, newvalue):
		logging.debug('dbus value changed, path: %s, newvalue: %s' % (path, newvalue))

		service = self._services.get(serviceName, None)
		if (service == None):
			return

		if (path == '/MinVoltage'):
			service.MinVoltage = newvalue
		elif (path == '/MaxVoltage'):
			service.MaxVoltage = newvalue

	############################################
	# if the value recieved has changed it
	# sends the toggle switch serial message to
	# the pysical device
	############################################
	def _try_toggle_serial_switch_value(self, name, newvalue):

		try:
			if (self._serialService == None or self._curData == None):
				logging.debug('_try_toggle_serial_switch_value: serial service or curData is None')
				return False

			if not (newvalue == 1 or newvalue == 0):
				logging.debug('_try_toggle_serial_switch_value: invalid value. value must be 0 or 1 for ' + name)
				return False

			curValue = self._curData.get_value(name)

			if (curValue != newvalue):
				return self._serialService.toggle_switch(name)

		except Exception as ex:
			logging.error("Error in _try_change_value %s" % (ex))

		return False

	############################################
	# starts and stops the dbus tank service
	# There can be upto 3 three tanks.
	# FreshWater, GreyWaste1 and GreyWaste2
	############################################
	def _start_stop_tank_service(self, name, create_callback):
		logging.debug(f"_start_stop_tank_service: {name}")
		service = self._services.get(name, None)

		if (self._settings['show_' + name] == 1):
			if (service is None):
				logging.debug(f"_start_stop_tank_service: {name} creating")

				service_name, display_name, fluid_type = create_callback()

				_, _, device_instance = self._vrm_parts[service_name]
				service_name = switch_service.serviceNameBuilder(
						dbus_constants.SERVICE_TYPE_TANK, f"_id_{device_instance}_{self._sid}")

				service = tank_service(display_name, self._serial_port, service_name, device_instance, fluid_type, 1.0)

				self._services[name] = service
			else:
				logging.debug(f"_start_stop_tank_service: {name} already running")
		elif (service):
			logging.debug(f"_start_stop_tank_service: {name} removing")
			self._services.pop(name)
			service.unregister()

	############################################
	# starts and stops the dbus switch service
	# The nord electornics 194 has 4 service
	# switches. Aux, Water Pump, Internal Lights &
	# External Lights
	############################################
	def _start_stop_switch_service(self):
		logging.debug("_start_stop_switch_service in")

		service = self._services.get("switches", None)
		if service:
			logging.debug("_start_stop_switch_service: unregister")
			service.unregister()
			service = None
			self._services.pop("switches")
		else:
			logging.debug("_start_stop_switch_service: Not running")


		switches = []

		#if statements are not needed as Venus OS hides switches using ShowUIControl

		#if (switches.ShowUIControl("InternalLights") == 1):
		switches.append("Internal Lights")

		#if (switches.ShowUIControl("ExternalLights") == 1):
		switches.append("External Lights")

		#if (switches.ShowUIControl("WaterPump") == 1):
		switches.append("Water Pump")

		#if (switches.ShowUIControl("Aux") == 1):
		switches.append("Aux")

		if len(switches) != 0:

			_, _, device_instance = self._vrm_parts['Switches']
			serviceName = switch_service.serviceNameBuilder(
					dbus_constants.SERVICE_TYPE_SWITCH, f"_id_{device_instance}_{self._sid}")

			self._services["switches"] = switch_service(
											"Electrics",
											self._serial_port,
											serviceName,
											device_instance,
											switches,
											onValueChangedCallback = self._dbus_switch_value_changed)

	############################################
	# Starts the dbus vehicle battery service
	# the ne shunt also has a leisure battery
	# but this is not likely needed in Victron
	# setup
	############################################
	def _start_battery_services(self):

		logging.debug("_start_battery_services in")

		service = self._services.get("cab_battery", None)

		if (service == None):
			_, _, device_instance = self._vrm_parts['CabBattery']
			serviceName = battery_service.serviceNameBuilder(
					dbus_constants.SERVICE_TYPE_BATTERY, f"_id_{device_instance}_{self._sid}")

			self._services["cab_battery"] = battery_service("Vehicle Battery",
														self._serial_port,
														serviceName,
														device_instance
														capacity = 0,
														onValueChangedCallback = self._dbus_cab_battery_value_changed)

		service = self._services.get("leisure_battery", None)
		if (service == None):
			_, _, device_instance = self._vrm_parts['LeisureBattery']
			serviceName = battery_service.serviceNameBuilder(
					dbus_constants.SERVICE_TYPE_BATTERY, f"_id_{device_instance}_{self._sid}")

			self._services["leisure_battery"] = battery_service("Leisure Battery",
														self._serial_port,
														serviceName,
														device_instance,
														capacity = 0,
														onValueChanged = self._dbus_leisure_battery_value_changed)

	############################################
	# starts and stops all services
	# note: only starts the vehicle battery service
	############################################
	def _start_stop_services(self, dbusservice_name = "", newValue = None):

		if (dbusservice_name == "" or dbusservice_name.endswith("FreshWaterTank")):
			self._start_stop_tank_service("fresh_water_tank",
				createCallback=lambda: ("FreshWaterTank", "Fresh Water", dbus_constants.FLUID_TYPE_FRESH_WATER))

		if (dbusservice_name == "" or dbusservice_name.endswith("GreyWasteTank")):
			self._start_stop_tank_service("grey_waste_tank",
				createCallback=lambda: ("GreyWasteTank", "Grey Waste", dbus_constants.FLUID_TYPE_WASTE_WATER))

		if (dbusservice_name == "" or dbusservice_name.endswith("GreyWasteTank2")):
			self._start_stop_tank_service("grey_waste_tank",
				createCallback=lambda: ("GreyWasteTank2", "Grey Waste 2", dbus_constants.FLUID_TYPE_WASTE_WATER))

		if (dbusservice_name == "" or dbusservice_name.endswith("Switch")):
			self._start_stop_switch_service()

		if (dbusservice_name == ""):
			self._start_battery_services()

		if (len(self._services)):
			first_value = next(iter(self._services.values()))
			self._settings['/ServiceName'] = first_value

		# start stop the serial service as required.
		self._start_stop_serial_service()

	############################################
	# initial setup of services and settings
	############################################
	def initialize(self):

		self._services = dict()

		self._initializeSettings()

		self._start_stop_services()

	############################################
	# updates a dbus service value from the
	# passed physical device value
	############################################
	def update_dbus_item(self, serviceName, servicePath, newValue):
		globals.log_verbose("update_dbus_item in")

		dbus_service = self._services.get(serviceName, None)
		if dbus_service:
			globals.log_verbose(f"update_dbus_item set_value: {servicePath}/newValue = {newValue}")
			dbus_service.set_value(servicePath, newValue)

		else:
			globals.log_verbose(f"update_dbus_item: serviceName = None ({serviceName})" )

		globals.log_verbose("update_dbus_item out")


	############################################
	# reads the 485 serial data from from the
	# ne-shunt and passes any changed values
	# to the dbus
	# returns True to continue
	# calling code should call this code continualy
	# for example: GLib.timeout_add(1000, nuss._update)
	############################################
	def _update(self):
		if self._cancelled:
			return False

		globals.log_verbose("_update in")

		if (self._serialService == None):
			globals.log_verbose("_update out ss=None")
			return True

		globals.log_verbose("read_data in")
		data = self._serialService.read_data()
		if not data:
			globals.log_verbose("_update out: no data returned")
			return True

		if self._cancelled:
			return False

		if (data == self._lastData):
			globals.log_verbose("no change exiting...")
			return True

		#logging.debug(f"data: {data}\n_lastData:{self._lastData}")

		newData = ne_shunt_data(data)
		#copy curData so we can update _curData and we don't get
		# recursive updates from update_item
		curData = self._curData.clone() if self._curData else None

		for key, value in newData.diff(curData):

			logging.info(f"value changed: {key} = {value}")

			match key:
				case 'fresh_water_tank' | "grey_waste_tank" | 'grey_waste_tank2':
					self.update_dbus_item(key, "/Level", value)
				case 'external_lights':
					self.update_dbus_item("switches", "/SwitchableOutput/ExternalLights/State", value)
				case 'internal_lights':
					self.update_dbus_item("switches", "/SwitchableOutput/InternalLights/State", value)
				case 'water_pump':
					self.update_dbus_item("switches", "/SwitchableOutput/WaterPump/State", value)
				case 'aux':
					self.update_dbus_item("switches", "/SwitchableOutput/Aux/State", value)
				case 'cab_battery' | 'leisure_battery':
					self.update_dbus_item(key, "/Voltage", value)
					dbus_service = self._services.get(key, None)
					if dbus_service:
						self.update_dbus_item(key, "/Soc", dbus_service.calcBatterySoc(value))

		globals.log_verbose("_update out")

		 #keep at end, helps dbus events from turning off values before we are populated
		self._curData = newData
		self._lastData = data

		return True