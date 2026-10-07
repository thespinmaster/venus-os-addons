# vespera Mermaid diagrams

This document captures code-level flows for the vespera addon.

Related: [Installer Integration Patterns (Developer Note)](installer-integration-patterns.md)

## 1) High-level architecture

```mermaid
flowchart LR
    UI[QML Pages\nOpkgPageSettings*.qml] --> VMJS[QML JS Helpers\nopkgPageSettingsPackages.js\nopkg-utils.js\nopkg-custom-device.js]
    UI --> BRIDGE[OpkgBridge\nQt C++ plugin]
    VMJS --> BRIDGE

    BRIDGE --> PROC[QProcess]
    PROC --> DEV[/device helper script/]
    PROC --> FEED[/feed helper script/]
    PROC --> PKG[/package helper script/]
    PROC --> PY[python3 json-helper.py\nfeed list and package list]

    PY --> CACHE[/tmp/vespera/\nfeeds.json, packages.json/]
    UI --> FILE[FileHelper.readFile]
    FILE --> CACHE
```

## 2) Package list/install/upgrade/remove flow

```mermaid
sequenceDiagram
    participant User
    participant PackagesPage as OpkgPageSettingsPackages.qml
    participant Vm as opkgPageSettingsPackages.js
    participant Bridge as OpkgBridge
    participant Runner as package helper / python helper
    participant Cache as /tmp/vespera/packages.json

    User->>PackagesPage: Open page
    PackagesPage->>Vm: loadPackages(opkgBridge, model, "package list", "")
    Vm->>Bridge: start(["package", "list"])
    Bridge->>Runner: resolveCommand + QProcess.start
    Runner-->>Cache: Write package list JSON
    Runner-->>Bridge: exit 0
    Bridge-->>PackagesPage: finished(0,0)
    PackagesPage->>PackagesPage: loadPackagesFromFile(packagesPath)
    PackagesPage->>Cache: FileHelper.readFile
    PackagesPage->>PackagesPage: populate ListModel

    User->>PackagesPage: Install/Upgrade/Remove action
    PackagesPage->>Vm: doInstllerAction(action, packageName, noAction)
    Vm->>Bridge: start(["package", action, packageName, ...])
    Bridge-->>PackagesPage: outputLine/errorLine (streamed log)
    Bridge-->>PackagesPage: finished(exitCode, status)
    PackagesPage->>PackagesPage: clear busy state + finalize log callback
```

## 3) Feed management flow

```mermaid
sequenceDiagram
    participant User
    participant FeedsPage as OpkgPageSettingsFeeds.qml
    participant Bridge as OpkgBridge
    participant FeedRunner as feed helper / python helper
    participant Cache as /tmp/vespera/feeds.json

    User->>FeedsPage: Open Feeds page
    FeedsPage->>Bridge: start(["feed", "list"])
    Bridge->>FeedRunner: run python helper for list
    FeedRunner-->>Cache: Write feeds JSON
    Bridge-->>FeedsPage: finished(0,0)
    FeedsPage->>Cache: FileHelper.readFile(feedsPath)
    FeedsPage->>FeedsPage: feedsModel = parsed feeds

    alt Add feed
        User->>FeedsPage: Add + confirm
        FeedsPage->>Bridge: start(["feed", "add", name, url])
    else Edit feed
        User->>FeedsPage: Edit + confirm
        FeedsPage->>Bridge: start(["feed", "edit", name, url, oldName])
    else Remove feed
        User->>FeedsPage: Remove
        FeedsPage->>Bridge: start(["feed", "remove", name])
    end

    Bridge-->>FeedsPage: finished(exitCode, status)
    FeedsPage->>FeedsPage: update/remove local model + toast
```

## 4) Install / upgrade / remove lifecycle

```mermaid
sequenceDiagram
    autonumber

    actor User
    participant OPKG as opkg
    participant PRE as preinst/prerm
    participant Inst as installer-lib
    participant Vlib as vespera-lib
    participant Dbus as vespera-dbus-lib
    participant FS as package files
    participant SYS as system
    participant Vcli as vespera CLI

    User->>OPKG: install / upgrade / remove

    alt Install
        OPKG->>PRE: run preinst
        PRE->>Inst: invoke installer
        Inst->>Vlib: overlay-register app
        Vlib->>SYS: overlay ready before filesystem mutation
        Inst->>Dbus: build manifest and apply DBus settings
        Dbus->>SYS: AddSettings / SetValue
        Inst->>FS: copy files / apply patches
        OPKG-->>Vcli: install complete
        Vcli->>Vlib: enable app / start services
        Vlib->>SYS: runtime activation
    else Upgrade
        OPKG->>PRE: run preinst / upgrade hooks
        PRE->>Inst: invoke installer
        Inst->>Vlib: overlay-register app
        Vlib->>SYS: overlay ready before filesystem mutation
        Inst->>Dbus: read previous manifest and compute delta
        Dbus->>SYS: add/remove changed settings only
        Inst->>FS: update files / patches
        OPKG-->>Vcli: upgrade complete
        Vcli->>Vlib: enable app / restart services
        Vlib->>SYS: runtime activation
    else Remove
        OPKG->>PRE: run prerm
        PRE->>Inst: invoke installer
        Inst->>Vlib: overlay-unregister app
        Vlib->>SYS: remove overlay before teardown
        Inst->>Dbus: remove package manifest
        Dbus->>SYS: RemoveSettings
        Inst->>FS: remove files / revert patches
        OPKG-->>Vcli: remove complete
        Vcli->>Vlib: disable app / finalize cleanup
        Vlib->>SYS: runtime deactivation
    end
```

This sequence intentionally separates concerns:
- `installer-lib` handles package lifecycle orchestration
- `vespera-lib` owns overlay and runtime activation/deactivation
- `vespera-dbus-lib` owns package DBus state and upgrade deltas
- the `vespera` CLI performs post-opkg runtime finalization only

## 5) Responsibility map

```mermaid
flowchart TB
    subgraph Pkg[Package lifecycle]
        Inst[installer-lib]
        Pre[package preinst / prerm]
    end

    subgraph App[App runtime / system state]
        Vlib[vespera-lib]
        Ovr[overlay registration]
        Svc[service enable / disable]
        Jso[delayed GUI json finalization]
    end

    subgraph Dbus[DBus state]
        D1[vespera-dbus-lib]
        M[package manifest + delta]
        Nav[CustomNavPages / CustomMenus]
        Set[SetValue queue]
    end

    subgraph Post[Post-opkg runtime finalization]
        Vcli[vespera CLI]
    end

    Pre --> Inst
    Inst --> Vlib
    Inst --> D1

    Vlib --> Ovr
    Vlib --> Svc
    Vlib --> Jso

    D1 --> M
    D1 --> Nav
    D1 --> Set

    Vcli --> Vlib
    Vcli --> Svc
    Vcli --> Jso
```

This map makes the intended boundary explicit:
- package lifecycle actions are triggered by the installer path
- overlay and runtime activation belong to `vespera-lib`
- DBus package state belongs to `vespera-dbus-lib`
- final app enablement post-opkg belongs to the CLI path only

## 6) Device setup step state machine

```mermaid
stateDiagram-v2
    [*] --> idle

    idle --> detect_device: doStep("detect-device")
    detect_device --> detect_device_done: finished 0 + optional JSON parsed
    detect_device --> error: finished non-zero

    detect_device_done --> apply_device: doStep("apply-device")
    apply_device --> apply_device_done: finished 0
    apply_device --> error: finished non-zero

    idle --> canceling: doStep("") while process running
    detect_device --> canceling: stop requested
    apply_device --> canceling: stop requested
    canceling --> canceling_done: process stops
    canceling_done --> idle

    error --> idle: doStep("error") cleanup/reset
    apply_device_done --> service_running: doStep("service-running")
    service_running --> idle
```

## Source anchors

- [src/opt/victronenergy/gui/qml/OpkgPageSettingsPackages.qml](../src/opt/victronenergy/gui/qml/OpkgPageSettingsPackages.qml)
- [src/opt/victronenergy/gui/qml/opkgPageSettingsPackages.js](../src/opt/victronenergy/gui/qml/opkgPageSettingsPackages.js)
- [src/opt/victronenergy/gui/qml/OpkgPageSettingsFeeds.qml](../src/opt/victronenergy/gui/qml/OpkgPageSettingsFeeds.qml)
- [src/opt/victronenergy/gui/qml/OpkgPageSettingsDeviceSetup.qml](../src/opt/victronenergy/gui/qml/OpkgPageSettingsDeviceSetup.qml)
- [src/qmlplugin/OpkgBridge.cpp](../src/qmlplugin/OpkgBridge.cpp)
- [src/data/apps/vespera/service-commands/json-helper.py](../src/data/apps/vespera/service-commands/json-helper.py)