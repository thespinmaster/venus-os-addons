# opkg-manager Test Plan

## Overview
Comprehensive testing for opkg-manager installation/removal and core features.

---

## Phase 1: Installation & Service Startup

### 1.1 Fresh Install
- [ ] Install opkg-manager package via opkg
- [ ] Verify `/data/opkg-manager/` directory structure exists
- [ ] Verify `/opt/victronenergy/gui/` QML pages present

### 1.2 UI Integration
- [ ] Venus GUI loads without errors
- [ ] opkg-manager pages appear in main menu
- [ ] UI connects to service (VBusItem paths functional)

---

## Phase 2: Core Features - Package Feed Management

### 2.1 Feed Configuration
- [ ] View current feeds via opkg (UI or CLI)
- [ ] Verify default feeds (opkg-manager, addons) present
- [ ] Check feed cache in `/tmp/opkg-manager/feeds.json`
- [ ] Manually add custom feed via UI (add URL, save, verify)
- [ ] Remove custom feed via UI (verify conf updated)
- [ ] Switch between release and development feeds

### 2.2 Feed Update
- [ ] Trigger `opkg update` via UI
- [ ] Verify package cache refreshes
- [ ] Check for package list errors
- [ ] Verify cache timestamp updates

---

## Phase 3: Core Features - Package Operations

### 3.1 Package Installation
- [ ] Search for available package in UI
- [ ] Install package via UI (non-critical test addon recommended)
- [ ] Verify package appears in installed list
- [ ] Verify `/data/conf/opkg-manager/installed-packages.conf` updated
- [ ] Check `/opt/victronenergy/<package>/` directory created
- [ ] If package has service, verify it starts and runs

### 3.2 Package Removal
- [ ] Remove installed package via UI
- [ ] Verify package removed from installed list
- [ ] Verify directories cleaned up
- [ ] Verify installed-packages.conf updated
- [ ] If package had service, verify it stops

### 3.3 Dry-Run Mode (NoAction)
- [ ] Enable dry-run via settings
- [ ] Attempt package install
- [ ] Verify no actual changes made
- [ ] Verify operation reports would-be results

---

## Phase 4: Serial Device Installer

### 4.1 Device Detection
- [ ] Connect USB serial device (FTDI or compatible)
- [ ] Check udev detection: `udevadm info /dev/ttyUSB*`
- [ ] Verify udev rules exist: `cat /etc/udev/rules.d/serial-starter.rules`
- [ ] Verify serial-starter.conf mapping: `cat /etc/venus/serial-starter.conf`

### 4.2 Automatic Service Spawning
- [ ] Verify `/service/serial-starter` service runs
- [ ] Check `/service/<service>.<ttyUSB0>` instance created
- [ ] Verify logs show device matched to service
- [ ] Disconnect and reconnect device; verify re-detection

---

## Phase 5: DBus Interface Testing

### 5.1 Direct DBus Calls
- [ ] Query package lists via DBus
- [ ] Trigger install operation via DBus (Request/Start)
- [ ] Monitor operation progress (Result/Json)
- [ ] Cancel operation mid-flight

### 5.2 Settings Persistence
- [ ] Write to `/Settings/OpkgManager/*` paths
- [ ] Reboot and verify settings persist
- [ ] Check `settings.xml` integration

---

## Phase 6: Uninstall & Cleanup

### 6.1 Package Removal
- [ ] Remove opkg-manager package via opkg
- [ ] Verify prerm hook executes cleanly
- [ ] Check for leftover processes: `ps aux | grep opkg`

### 6.2 Filesystem Cleanup
- [ ] Verify service removed: `/service/opkgmanager` gone
- [ ] Verify DBus interface unregistered
- [ ] Check config files cleaned: `/etc/opkg/opkg-manager.conf` symlink removed
- [ ] Verify QML pages removed (or gracefully hidden)
- [ ] Check `/var/log/opkg-manager/` logs for clean shutdown

### 6.3 Fresh Install After Removal
- [ ] Reinstall opkg-manager package
- [ ] Verify clean install (no conflicts, settings reset)
- [ ] Run Phase 1 checks again

---

## Phase 7: Edge Cases & Stress Tests

### 7.1 Network Issues
- [ ] Block feed URL, attempt update (verify error handling)
- [ ] Disconnect network, attempt install (graceful fail)
- [ ] Restore network, verify recovery

### 7.2 Filesystem Issues
- [ ] Fill disk to 90%, attempt large package install (fail gracefully)
- [ ] Restore disk space, retry install (succeeds)

### 7.3 Concurrent Operations
- [ ] Start install, trigger second operation immediately (queue/block)
- [ ] Start install, restart service mid-operation (cleanup)

### 7.4 Multiple Reboots
- [ ] Install packages, reboot 3 times
- [ ] Verify packages persist, service restarts cleanly each time

---

## Phase 8: Test Evidence

### Required Logs to Collect
- [ ] `/var/log/opkg-manager/startup.log` (install/startup)
- [ ] `/var/log/opkg-manager/system.log` (operations)
- [ ] `/var/log/gui/current` (UI errors)
- [ ] `journalctl -u opkgmanager` (runit logs)

### Performance Benchmarks (Optional)
- [ ] Time to install small package (< 100KB)
- [ ] Time to install large package (> 5MB)
- [ ] Feed update time (with/without cache)
- [ ] UI responsiveness during install

---

## Test Execution Notes

1. **Test Device**: Use Raspberry Pi 4 or similar (Venus OS device)
2. **Test Packages**: Use non-critical addons (test-install, test-service) for safety
3. **Network**: Ensure stable internet; test offline scenarios separately
4. **Backup**: Create backup before Phase 1 to restore if needed
5. **Logging**: Capture all phase transitions for troubleshooting

---

## Sign-Off

| Phase | Status | Date | Notes |
|-------|--------|------|-------|
| 1. Installation & Startup | ☐ | | |
| 2. Feed Management | ☐ | | |
| 3. Package Operations | ☐ | | |
| 4. Serial Devices | ☐ | | |
| 5. DBus Interface | ☐ | | |
| 6. Uninstall & Cleanup | ☐ | | |
| 7. Edge Cases | ☐ | | |
| **Overall Status** | ☐ | | |
