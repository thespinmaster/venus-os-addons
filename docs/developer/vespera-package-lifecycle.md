# Vespera package lifecycle

This document captures the package-manager lifecycle and startup flow described in the Vespera library.

> Source: `vespera-lib` in the Vespera app package.

## Overview

The Vespera CLI wraps `opkg` rather than replacing it. The underlying package manager lifecycle remains in `opkg`; Vespera adds the pre/post hook orchestration, overlay reconciliation, service control, and install-state tracking around it.

## Wrapper flow

```text
1. parse CLI args
2. if command is install/remove/upgrade:
      vespera_lib_pre_install "$command" "$@"
3. opkg -f "${VESPERA_COMBINED_CONF_FILE}" "$command" "$@"
4. if the command completed successfully:
      vespera_lib_post_install "$command"
```

## Package manager lifecycle

### Install

```text
vespera install <pkg>
  │
  ├─ vespera_lib_pre_install "install"
  │    ├─ guard against concurrent GUI/package activity
  │    ├─ __vespera_lib_initialize; sets temporary working dir / lock state
  │    └─ verify fs + package-use constraints
  │
  ├─ opkg -f "${VESPERA_COMBINED_CONF_FILE}" install <pkg>
  │    ├─ CONTROL/preinst -> overlay-register <pkg>
  │    ├─ unpack package files
  │    ├─ CONTROL/postinst -> <pkg>.installer "install"
  │    │    └─ installer-lib initialize/install
  │    │         ├─ __installer_lib_process_default_conf_files
  │    │         ├─ __installer_lib_init_overlay_paths
  │    │         ├─ __installer_lib_write_dbus_settings_to_dbus_list_file
  │    │         ├─ __installer_lib_patch_files add
  │    │         ├─ __installer_lib_add_dbus_settings_from_dbus_list_file
  │    │         └─ __installer_lib_phase_apply_runtime
  │    │              └─ write app state to $VESPERA_WORKING_DIR/$VESPERA_INSTALL_STATE_FILE
  │    └─ package script completes
  │
  └─ vespera_lib_post_install "install"
       ├─ __vespera_send_gui_interrupt_signal
       ├─ process install state (enabled/disabled/removed)
       ├─ enable apps, refresh devices, restart services
       ├─ vespera_lib_index
       └─ __vespera_lib_cleanup
```

### Remove

```text
vespera remove <pkg>
  │
  ├─ vespera_lib_pre_install "remove"
  │    ├─ guard against concurrent GUI/package activity
  │    ├─ __vespera_lib_initialize; sets temporary working dir / lock state
  │    └─ verify package can be removed safely
  │
  ├─ opkg -f "${VESPERA_COMBINED_CONF_FILE}" remove <pkg>
  │    ├─ CONTROL/prerm -> <pkg>.installer "remove"
  │    │    └─ installer-lib initialize/remove
  │    │         ├─ __installer_lib_patch_files remove
  │    │         ├─ __installer_lib_remove_dbus_settings_from_file
  │    │         ├─ __installer_lib_phase_remove_runtime
  │    │         ├─ write package status to $VESPERA_WORKING_DIR/$VESPERA_INSTALL_STATE_FILE
  │    │         └─ __installer_lib_remove_cleanup
  │    ├─ package files are deleted
  │    └─ CONTROL/postrm -> overlay-unregister unless upgrade path is active
  │
  └─ vespera_lib_post_install "remove"
       ├─ __vespera_send_gui_interrupt_signal
       ├─ remove GUI json files and empty app dirs
       ├─ restart Venus services if required
       ├─ vespera_lib_index
       └─ __vespera_lib_cleanup
```

### Upgrade

```text
vespera upgrade <pkg>
  │
  ├─ vespera_lib_pre_install "upgrade"
  │    ├─ guard against concurrent GUI/package activity
  │    ├─ __vespera_lib_initialize
  │    └─ verify upgrade path + filesystem constraints
  │
  ├─ opkg -f "${VESPERA_COMBINED_CONF_FILE}" upgrade <pkg>
  │    ├─ old package: CONTROL/prerm -> <oldpkg>.installer "upgrade-remove"
  │    │    └─ installer-lib initialize/remove (upgrade path)
  │    │         ├─ __installer_lib_patch_files remove
  │    │         ├─ __installer_lib_remove_dbus_settings_from_file
  │    │         ├─ __installer_lib_phase_remove_runtime
  │    │         └─ __installer_lib_remove_cleanup
  │    ├─ new package: CONTROL/preinst -> overlay-register
  │    ├─ unpack new package files
  │    ├─ new package: CONTROL/postinst -> <newpkg>.installer "upgrade-install"
  │    │    └─ installer-lib initialize/install (upgrade path)
  │    │         ├─ preserve enabled state / detect upgrade
  │    │         ├─ __installer_lib_write_dbus_settings_to_dbus_list_file
  │    │         ├─ __installer_lib_patch_files add
  │    │         ├─ __installer_lib_add_dbus_settings_from_dbus_list_file
  │    │         └─ __installer_lib_phase_apply_runtime
  │    └─ old package: CONTROL/postrm -> overlay-unregister if not in upgrade path
  │
  └─ vespera_lib_post_install "upgrade"
       ├─ __vespera_send_gui_interrupt_signal
       ├─ process $VESPERA_WORKING_DIR/$VESPERA_INSTALL_STATE_FILE
       ├─ re-enable apps or restart services as needed
       ├─ vespera_lib_index
       └─ __vespera_lib_cleanup
```

## Vespera boot lifecycle

### /data/rcS.local

```text
/data/rcS.local
  │
  └─ __vespera_lib_rcS_local
       ├─ __vespera_lib_configure_installed
       │    ├─ if no /opt/victronenergy/version exists: copy version file and return 0
       │    ├─ if version matches current firmware: return 0
       │    └─ if version differs: firmware change detected
       │         ├─ expand root filesystem if needed
       │         ├─ reconcile overlays / stale state cleanup
       │         ├─ remount overlays and re-run opkg configure for installed packages
       │         └─ continue with app/service startup once reconciliation is complete
       │
       ├─ if retval == 0: mount overlays via __vespera_lib_overlay overlay-mount
       ├─ else if retval != 2: stop and return
       ├─ for each enabled app: copy and start the app's controlled service(s)
       ├─ Vespera owns startup execution; apps should not patch /data/rcS.local directly
       └─ __vespera_lib_execute_startup_scripts rcS.local
            └─ run numbered startup scripts in $VESPERA_DATA_DIR/info/*-rcS.local
               in numeric order, each logged to /var/log/vespera/startup.log
```

### /data/rc.local

```text
/data/rc.local
  │
  └─ __vespera_lib_rc_local
       ├─ Vespera owns startup execution; apps should not patch /data/rc.local directly
       └─ __vespera_lib_execute_startup_scripts rc.local
            └─ run numbered startup scripts in $VESPERA_DATA_DIR/info/*-rc.local
               in numeric order, each logged to /var/log/vespera/startup.log
```

## Startup script convention

- Numbered filenames determine execution order.
- Scripts are discovered under `$VESPERA_DATA_DIR/info/`.
- Each script is run as part of the `rcS.local` / `rc.local` boot chain.
- Execution is logged to `/var/log/vespera/startup.log`.

## Key design note

Vespera does not replace the package manager; it wraps `opkg` with lifecycle hooks, overlay reconciliation, service management, and app state transitions that keep the package installation model and boot model consistent across firmware upgrades and app changes.
