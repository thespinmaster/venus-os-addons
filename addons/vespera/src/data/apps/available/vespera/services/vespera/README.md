# vespera DBus Process Service


## DBus Service

- Service: com.victronenergy.vespera
- Interface for item access: com.victronenergy.BusItem

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

