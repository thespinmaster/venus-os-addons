# opkg-manager Mermaid diagrams

This document captures code-level flows for the opkg-manager addon.

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

    PY --> CACHE[/tmp/opkg-manager/\nfeeds.json, packages.json/]
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
    participant Cache as /tmp/opkg-manager/packages.json

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
    participant Cache as /tmp/opkg-manager/feeds.json

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

## 4) Device setup step state machine

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
- [src/data/opkg-manager/opkg-bridge/json-helper.py](../src/data/opkg-manager/opkg-bridge/json-helper.py)