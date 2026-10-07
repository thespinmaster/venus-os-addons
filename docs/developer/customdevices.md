# Custom Devices

## Dbus entries
  
### com.victronenergy.settings
Paths added by the Service when installed

/Settings/vespera/CustomServicePaths : `[DbusProductName]`|`[DbusProductName]`|`[DbusProductName]`  
/Settings/vespera/CustomServicePaths : "`Inetbox`|`NeShunt`|`DummyService`"  

Each value in CustomServicePaths is the path name under /Settings/vespera/CustomServices

/Settings/vespera/CustomServices/`[DbusProductName]`

Examples:  
/Settings/vespera/CustomServices/`Inetbox`/...  
/Settings/vespera/CustomServices/`NeShunt`/...  
/Settings/vespera/CustomServices/`DummyService`/...  

/Settings/vespera/CustomServices/`[DbusProductName]`/`[Setting]`  

| Setting | Value | Required | Notes |
|---|---|---|---|
| `ProductName`    | "Inetbox"      |yes| For display, can be any text
| `ServiceName`    | "dbus-inetbox" |yes| The name of the service folder name
| `UsbMappingName` | "inetbox"      |no| Used in serial-starter.rule file and serial-starter.conf file.<br>If not supplied the ServiceName is normalized and used.
| `UsbProps`       | "ID_VENDOR,ID_MODEL,ID_SERIAL" |no| Comma separated props used to uniquily identify the device <br>If not supplied the following properties are used "ID_VENDOR,ID_MODEL,ID_SERIAL"

### com.victronenergy.temperature.dbus_inetbox_sid_c7f2
Values added by the service (when running)  

| Setting | Value | Note |
|---|---|---|
| `CustomDevicePage`    | "OpkgCustomDevicePage_neshunt"  |  The name of the qml page to use
| `CustomName`          | "My device 1"           |  User inputed text
| `ServiceName`         | "`[ServiceName]`"       |  From /Settings/vespera/CustomServices/`[DbusProductName]`/`[ServiceName]`
| `Sid`                 | "`c7f2`"    |  A unique value used to find the device

 
## Files

### serial-starter.rules
 
ACTION=="add", ENV{ID_BUS}=="usb", ENV{ID_SERIAL}=="`[UsbProp(n)]`", ENV{SERIAL_DEVICE_ID}="`[Sid]`", ENV{VE_SERVICE}="`[UsbMappingName]`|`[ServiceName] (normalized)`"
 
#### example

ACTION=="add", ENV{ID_BUS}=="usb", ENV{ID_SERIAL}=="**FTDI_Intetbox_BG02CS2X**", ENV{SERIAL_DEVICE_ID}="**c7f2**", ENV{VE_SERVICE}="**inetbox**"

#### notes
When the system finds the device using the rule in the serial-starter.rules file it adds
SERIAL_DEVICE_ID=c7f2
VE_SERVICE=inetbox
To the udev properties

using the following you can get the SERIAL_DEVICE_ID value from the tty port name
```
 udevadm info --query=property --name="ttyUSB0" | sed -n "s/^SERIAL_DEVICE_ID=//p"
```

### serial-starter.conf

service **[UsbMappingName]**|**[service_name (normalized)]** **[ServiceName]**

#### example
  
```
service inetbox dbus-inetbox
service cgwacs		dbus-cgwacs
service gps		gps-dbus
...
```

## Folders:
/opt/victronenergy/service-templetes/`[ServiceName]`  
This folder is used when a device is matched to a service. The service is copied from the template folder to the service folder and appended with the port name  
/service/`[ServiceName]`.`TTY`  
#### example
```
/opt/victronenergy/service-templetes/dbus-dummy-service -> /service/dbus-dummy-service.ttyUSB0
```

## dbus service values
### TODO

## dbus device settings
### TODO