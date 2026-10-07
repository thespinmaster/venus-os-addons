#!/usr/bin/python3 -u

# === All code below is to simply run it from the commandline for debugging purposes ===

# It will created a dbus service called com.victronenergy.pvinverter.output.
# To try this on commandline, start this program in one terminal, and try these commands
# from another terminal:
# dbus com.victronenergy.pvinverter.output
# dbus com.victronenergy.pvinverter.output /Ac/Energy/Forward GetValue
# dbus com.victronenergy.pvinverter.output /Ac/Energy/Forward SetValue %20
#
# Above examples use this dbus client: http://code.google.com/p/dbus-tools/wiki/DBusCli
# See their manual to explain the % in %20

import os
import sys
import time
import signal
import logging

sys.path.append(os.path.join(os.path.dirname(__file__), 'ext'))

from dbus_test_device_service import DbusTestDeviceService
from argparse import ArgumentParser
from gi.repository import GLib # type: ignore

log = logging.getLogger()

def main():

	args = getArgs()

	#filename="/data/apps/dbus-ne-shunt.log",
	logging.basicConfig(
		format="%(asctime)s;%(levelname)-8s %(message)s",
		level=(logging.DEBUG if args.debug else logging.INFO),
	)

	serial = args.serial
	if not serial.startswith("/dev/"):
		serial="/dev/" + serial

	log.info("Serial port:" + serial)
	log.info("Serial device id:" + args.sid)

	from dbus.mainloop.glib import DBusGMainLoop

	# Have a mainloop, so we can send/receive asynchronous calls to and from dbus
	DBusGMainLoop(set_as_default=True)

	service = DbusTestDeviceService(
			serialPort=serial,
			sid=args.sid,
			)

	time.sleep(2)
	GLib.timeout_add(1000, service._update)

	log.info("Connected to dbus, and switching over to GLib.MainLoop() (= event based)")

	mainloop = GLib.MainLoop()

	def handle_sigint(signum, frame):
		service.close()
		mainloop.quit()

	signal.signal(signal.SIGINT, handle_sigint)

	mainloop.run()
	log.info("EXITED: test-device")

def getArgs():
	parser = ArgumentParser(description="test-device-service", add_help=True)
	parser.add_argument("-d", "--debug", help="enable debug logging", action="store_true")
	parser.add_argument("-r", "--readonly", help="only read data from the serial port", action="store_true")
	parser.add_argument("-i", "--sid", help="serial device id (required)")
	parser.add_argument("-s", "--serial", help="tty (required)")

	args = parser.parse_args()
	if not args.serial:
		log.error("No serial port specified, see -h")
		exit(1)

	if not args.sid:
		log.error("No serial device id, see -h")
		exit(1)

	return args

if __name__ == "__main__":
	main()