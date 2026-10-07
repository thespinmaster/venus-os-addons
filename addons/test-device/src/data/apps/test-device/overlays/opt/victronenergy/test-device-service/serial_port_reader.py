#!/usr/bin/env python3

#from serial import (Serial, EIGHTBITS ,PARITY_NONE,STOPBITS_ONE)
import time
import serial

class SerialPortReader(object):
		
    SERIAL_BAUD_RATE=9600
    
    _serialPort : str
    _serial : serial.Serial
 
    def __init__(self, port_name):
  
        self._serial = serial.Serial(port=port_name,
                                        baudrate=self.SERIAL_BAUD_RATE,
                                        bytesize=serial.EIGHTBITS,
                                        parity=serial.PARITY_NONE,
                                        stopbits=serial.STOPBITS_ONE,
                                        xonxoff=False,
                                        rtscts=False,
                                        dsrdtr=False,   # also typically off unless explicitly needed
                                        timeout=0.003   # blocking read (like raw mode)
            )

    def read_data(self):
        
        data=""
        if self._serial and not self._serial.is_open:
            self._serial.open()
            if not self._serial.is_open:
                return data
            
        
        while len(data) < 10:
            time.sleep(0.1)
            if self._serial.in_waiting > 0:
                value = self._serial.read()
                data+=value.hex()
            else:
                time.sleep(0.1)

        return data
                     
    def close(self):
        if self._serial and self._serial.is_open:
            self._serial.close()
 
 