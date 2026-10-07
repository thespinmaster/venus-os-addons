# Mount Shares Usage

This add-on is primarily intended for users working over SSH on Venus OS.

## Script Location

Use the Mount Shares helper script at:

```bash
/data/apps/mount-shares/mount-lib
```

## Common Commands

Mount and save a share configuration:

```bash
/data/apps/mount-shares/mount-lib mount --targetpath /data/mnt/myshare -t cifs -o username=myuser,password=mypass,exec,mfsymlinks //192.168.1.10/share /data/mnt/myshare
```

Mount all saved shares:

```bash
/data/apps/mount-shares/mount-lib mount-all
```

Interactive prompt mode (asks for type, source, target, and credentials):

```bash
/data/apps/mount-shares/mount-lib
```

## NFS Example

```bash
/data/apps/mount-shares/mount-lib mount --targetpath /data/mnt/nfsmedia -t nfs 192.168.1.20:/export/media /data/mnt/nfsmedia
```

## Configuration File and Purpose

Saved mount definitions are stored in:

```bash
/data/conf/mount-shares.conf
```

How it is used:

* Each non-comment line contains the mount arguments and target path.
* The target path is used as the unique key when updating existing entries.
* This file is read by `mount-all` to restore shares.

## Reboot Behavior

Shares mounted through `mount-lib mount` are automatically restored after reboot.
On startup, Mount Shares runs:

```bash
/data/apps/mount-shares/mount-lib mount-all
```

This reads `/data/conf/mount-shares.conf` and remounts all saved entries.

## Tips

* Ensure target directories are under `/data/mnt/` or another persistent path you control.
* Confirm network availability before mounting remote shares.
* If a mount fails, run the command manually over SSH to inspect the error output.

---
#### Previous - [Overview](overview.md)