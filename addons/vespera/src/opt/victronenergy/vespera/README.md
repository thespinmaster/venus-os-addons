# opkg-manager DBus Process Service

This service replaces the QML plugin `ProcessRunner` and the transitional wrapper scripts with a Python DBus value service that QML can access directly through `VBusItem`.

It executes these existing helper scripts unchanged:
- /data/opkg-manager/process-runner/opkg
- /data/opkg-manager/process-runner/serial-device-installer

## DBus Service

- Service: com.victronenergy.opkgmanager
- Interface for item access: com.victronenergy.BusItem

QML interacts with writable/readable paths instead of calling DBus methods.

## Writable Request Paths

- /Request/ArgsJson
- /Request/Start
- /Request/Cancel

## Readable State/Event/Result Paths

- /State/Running
- /State/Stopping
- /State/RequestId
- /Event/StdoutLine
- /Event/StdoutSeq
- /Event/StderrLine
- /Event/StderrSeq
- /Event/FinishedSeq
- /Result/ExitCode
- /Result/ExitStatus
- /Result/Json
- /Result/Error

## JSON Result Behavior

The service populates `/Result/Json` for commands whose final structured result is either:
- a JSON string written to stdout
- a file path to JSON written to stdout

Currently this is used for:
- `opkg get-feeds`
- `opkg list-packages`
- `serial-device-installer detect-device`

## Lifecycle

- Supervised service template: /opt/victronenergy/service/opkg-manager-service
- Runtime supervised service: /service/opkg-manager-service
- Boot startup hook: /data/opkg-manager/rc.local.d/2/start-opkg-manager-service
- Start script: /opt/victronenergy/opkg-manager-service/start-opkg-manager-service.sh
- Stop script: /opt/victronenergy/opkg-manager-service/stop-opkg-manager-service.sh

The process runs as a runit service, so it is restarted automatically if it exits.
