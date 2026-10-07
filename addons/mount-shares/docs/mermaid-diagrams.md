# mount-shares Mermaid diagrams

## 1) Runtime architecture

```mermaid
flowchart LR
    POSTINST[CONTROL postinst] --> REG[opkg_lib_register_package]
    POSTINST --> BOOTMOUNT[data mount-shares mount-lib mount-all]

    RCLOCAL[data mount-shares 2-rc-startup] --> COMMON[mount-lib]
    COMMON --> CONF[data conf mount-shares.conf]
    COMMON --> MOUNT[mount command]
    COMMON --> WAIT[mountpoint check loop]

    COMMON --> CIFS[sbin mount.cifs]
    COMMON --> NFS[sbin mount.nfs]
```

## 2) Mount all replay flow

```mermaid
sequenceDiagram
    participant Boot as rc.local script
    participant Common as mount-lib
    participant Conf as mount-shares.conf
    participant Kernel as mount command

    Boot->>Common: mount-all
    Common->>Conf: read saved lines
    loop each non-empty config line
        Common->>Common: parse args and target path
        Common->>Kernel: mount args target
    end
```

## Source anchors

- [src/data/apps/mount-shares/2-rc-startup](../src/data/apps/mount-shares/2-rc-startup)
- [src/data/apps/mount-shares/mount-lib](../src/data/apps/mount-shares/mount-lib)
- [src/CONTROL/postinst](../src/CONTROL/postinst)
- [src/CONTROL/postrm](../src/CONTROL/postrm)
