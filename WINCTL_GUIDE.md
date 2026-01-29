# winctl.sh User Guide

A comprehensive guide to managing Windows Docker containers with `winctl.sh`.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Commands Reference](#commands-reference)
- [Configuration](#configuration)
- [Interactive Menus](#interactive-menus)
- [Common Scenarios](#common-scenarios)
- [Troubleshooting](#troubleshooting)
- [Tips & Tricks](#tips--tricks)

---

## Overview

`winctl.sh` is a management script for running Windows virtual machines inside Docker containers. It provides:

- **22 Windows versions** from Windows 2000 to Windows 11
- **Simple commands** to start, stop, and manage containers
- **Interactive menus** when you don't specify a version
- **Status caching** for fast performance
- **Resource profiles** optimized for modern and legacy systems

### Supported Windows Versions

| Category | Versions |
|----------|----------|
| **Desktop** | win11, win11e, win11l, win10, win10e, win10l, win81, win81e, win7, win7e |
| **Legacy** | vista, winxp, win2k |
| **Server** | win2025, win2022, win2019, win2016, win2012, win2008, win2003 |
| **Tiny** | tiny11, tiny10 |

### ARM64 Support

The script auto-detects your CPU architecture. On ARM64 systems (e.g., Apple Silicon, Ampere), only the following versions are supported:

| Version | Name |
|---------|------|
| win11 | Windows 11 Pro |
| win11e | Windows 11 Enterprise |
| win11l | Windows 11 LTSC |
| win10 | Windows 10 Pro |
| win10e | Windows 10 Enterprise |
| win10l | Windows 10 LTSC |

To run on ARM64, set the Docker image in your `.env.modern` file:

```bash
WINDOWS_IMAGE=dockurr/windows-arm
```

The `winctl.sh list` command shows `[x86 only]` tags on ARM64 for unsupported versions, and `winctl.sh start` blocks unsupported versions with a clear error message.

### Port Mappings

Each version has unique ports to avoid conflicts:

| Version | Web UI | RDP | Version | Web UI | RDP |
|---------|--------|-----|---------|--------|-----|
| win11 | 8011 | 3311 | win2025 | 8025 | 3325 |
| win10 | 8010 | 3310 | win2022 | 8022 | 3322 |
| win81 | 8008 | 3308 | win2019 | 8019 | 3319 |
| win7 | 8007 | 3307 | win2016 | 8016 | 3316 |
| vista | 8006 | 3306 | win2012 | 8112 | 3212 |
| winxp | 8005 | 3305 | win2008 | 8108 | 3208 |
| win2k | 8000 | 3300 | win2003 | 8003 | 3303 |
| tiny11 | 8111 | 3111 | tiny10 | 8110 | 3110 |

---

## Prerequisites

### Required

1. **Docker** - Container runtime
2. **Docker Compose** - Container orchestration (plugin or standalone)
3. **KVM** - Hardware virtualization for near-native performance

### Check Prerequisites

Run the built-in check:

```bash
./winctl.sh check
```

Example output:
```
Prerequisites Check
────────────────────────────────────────────────────────────
[OK] Docker is available
[OK] Docker Compose plugin is available
[OK] KVM is available
[OK] TUN device is available
[OK] Memory OK: 16GB available (8GB needed)
[OK] Disk space OK: 500GB available (128GB needed)

[OK] All critical prerequisites passed!
```

### Fix Common Issues

**KVM not accessible:**
```bash
sudo usermod -aG kvm $USER
newgrp kvm  # or log out and back in
```

**Docker not running:**
```bash
sudo systemctl start docker
```

---

## Quick Start

### 1. Start a Windows VM

```bash
# Start Windows 11
./winctl.sh start win11

# Or use interactive menu
./winctl.sh start
```

### 2. Access the VM

After starting, you'll see connection details:

```
Connection Details:
  → Web Viewer: http://localhost:8011
  → RDP:        localhost:3311
```

- **Web Viewer**: Open in browser for quick access
- **RDP**: Use any RDP client for better performance

### 3. Check Status

```bash
./winctl.sh status
```

### 4. Stop the VM

```bash
./winctl.sh stop win11
```

---

## Commands Reference

### start

Start one or more containers.

```bash
# Start single version
./winctl.sh start win11

# Start multiple versions
./winctl.sh start win11 win10 winxp

# Interactive menu (no version specified)
./winctl.sh start
```

**What it does:**
1. Checks prerequisites (Docker, KVM)
2. Creates data directory if missing
3. Checks available resources
4. Starts the container
5. Shows connection details

---

### stop

Stop containers with a 2-minute grace period for clean shutdown.

```bash
# Stop single version
./winctl.sh stop win11

# Stop multiple versions
./winctl.sh stop win11 win10

# Stop all running containers
./winctl.sh stop all

# Interactive menu
./winctl.sh stop
```

**Note:** You'll be asked to confirm before stopping.

---

### restart

Restart containers.

```bash
./winctl.sh restart win11
```

---

### status

Show status of containers.

```bash
# All containers
./winctl.sh status

# Specific versions
./winctl.sh status win11 win10
```

Example output:
```
  VERSION      NAME                       STATUS     WEB      RDP
  ──────────────────────────────────────────────────────────────────
  win11        Windows 11 Pro             running    8011     3311
  win10        Windows 10 Pro             stopped    8010     3310
  winxp        Windows XP Professional    not created 8005    3305
```

---

### logs

View container logs.

```bash
# View logs
./winctl.sh logs win11

# Follow logs in real-time
./winctl.sh logs win11 -f
```

Press `Ctrl+C` to stop following logs.

---

### shell

Open an interactive bash shell inside the container.

```bash
./winctl.sh shell win11
```

Useful for debugging or accessing container internals.

---

### stats

Show real-time resource usage (CPU, memory, network).

```bash
# All running containers
./winctl.sh stats

# Specific containers
./winctl.sh stats win11 win10
```

Press `Ctrl+C` to exit.

---

### build

Build the Docker image locally from source.

```bash
./winctl.sh build
```

---

### rebuild

Destroy and recreate containers. Data in `/storage` is preserved.

```bash
./winctl.sh rebuild win11
```

**Warning:** You must type `yes` to confirm (destructive operation).

---

### list

List available Windows versions.

```bash
# All versions
./winctl.sh list

# By category
./winctl.sh list desktop
./winctl.sh list legacy
./winctl.sh list server
./winctl.sh list tiny
```

Example output:
```
Available Windows Versions
────────────────────────────────────────────────────────────

  DESKTOP
  ──────────────────────────────────────────────────
    win11      Windows 11 Pro               (8G RAM)
    win10      Windows 10 Pro               (8G RAM) [running]
    win7       Windows 7 Ultimate           (2G RAM)
```

---

### inspect

Show detailed information about a version.

```bash
./winctl.sh inspect win11
```

Example output:
```
Container Details: win11
────────────────────────────────────────────────────────────

  Version:      win11
  Name:         Windows 11 Pro
  Category:     desktop
  Status:       running
  Web Port:     8011
  RDP Port:     3311
  Resources:    modern
  Compose:      compose/desktop/win11.yml
```

---

### monitor

Real-time dashboard showing all containers.

```bash
# Default 5-second refresh
./winctl.sh monitor

# Custom refresh interval (10 seconds)
./winctl.sh monitor 10
```

Press `Ctrl+C` to exit.

---

### check

Run prerequisites check.

```bash
./winctl.sh check
```

---

### refresh

Force refresh the status cache.

```bash
./winctl.sh refresh
```

The cache is stored at `~/.cache/winctl/status.json` and auto-refreshes when:
- Cache is older than 7 days
- Cached data becomes stale
- After start/stop/restart/rebuild operations

---

## Configuration

### Environment Files

Two pre-configured environment files control VM resources:

| File | RAM | CPU | Disk | Used By |
|------|-----|-----|------|---------|
| `.env.modern` | 8G | 4 | 128G | Win 10/11, Server 2016+ |
| `.env.legacy` | 2G | 2 | 32G | Win 7/8, Vista, XP, 2000, Server 2003-2012, Tiny |

### Customizing Resources

Edit `.env.modern` or `.env.legacy`:

```bash
# Resources
RAM_SIZE=8G
CPU_CORES=4
DISK_SIZE=128G

# Credentials
USERNAME=docker
PASSWORD=admin

# Display
WIDTH=1280
HEIGHT=720

# Other
LANGUAGE=en
REGION=en-US
KEYBOARD=en-US
DHCP=N
SAMBA=Y
RESTART_POLICY=on-failure
DEBUG=N
```

### Available Settings

| Setting | Description | Default |
|---------|-------------|---------|
| `RAM_SIZE` | Memory allocation | 8G/2G |
| `CPU_CORES` | CPU cores | 4/2 |
| `DISK_SIZE` | Virtual disk size | 128G/32G |
| `USERNAME` | Windows username | docker |
| `PASSWORD` | Windows password | admin |
| `LANGUAGE` | Installation language | en |
| `REGION` | Region setting | en-US |
| `KEYBOARD` | Keyboard layout | en-US |
| `WIDTH` | Display width | 1280 |
| `HEIGHT` | Display height | 720 |
| `DHCP` | Use DHCP networking | N |
| `SAMBA` | Enable file sharing | Y |
| `RESTART_POLICY` | Container restart policy | on-failure |
| `DEBUG` | Debug mode | N |
| `WINDOWS_IMAGE` | Docker image | dockurr/windows |

### Restart Policy Options

| Value | Description |
|-------|-------------|
| `no` | Never restart automatically |
| `on-failure` | Restart only if container exits with error (default) |
| `always` | Always restart regardless of exit status |
| `unless-stopped` | Always restart unless manually stopped |

**Note:** With `on-failure` (default), shutting down Windows from inside will stop the container. With `unless-stopped` or `always`, the container will restart after Windows shutdown.

---

## Interactive Menus

When you don't specify a version, `winctl.sh` shows interactive menus.

### Category Selection

```
Select Category
────────────────────────────────────────────────────────────

  1) Desktop (Win 11, 10, 8.1, 7)
  2) Legacy (Vista, XP, 2000)
  3) Server (2025, 2022, 2019, 2016, 2012, 2008, 2003)
  4) Tiny (Tiny11, Tiny10)
  5) All versions
  6) Select individual versions

  Select [1-6]:
```

### Version Selection

```
Select Version(s)
────────────────────────────────────────────────────────────

   1) win11      Windows 11 Pro               [running]
   2) win11e     Windows 11 Enterprise
   3) win11l     Windows 11 LTSC
   4) win10      Windows 10 Pro               [stopped]

   a) Select all
   q) Cancel

  Select (numbers separated by spaces, or 'a' for all):
```

- Enter numbers separated by spaces: `1 3 4`
- Enter `a` for all versions
- Enter `q` to cancel

---

## Common Scenarios

### Scenario 1: Set Up a Development Environment

```bash
# Start Windows 10 for development
./winctl.sh start win10

# Access via web browser
# Open http://localhost:8010

# Or connect via RDP for better performance
# Use RDP client to connect to localhost:3310
```

### Scenario 2: Test Software on Multiple Windows Versions

```bash
# Start multiple versions
./winctl.sh start win11 win10 win7

# Check they're all running
./winctl.sh status

# Access each via their ports:
# - Win11: http://localhost:8011
# - Win10: http://localhost:8010
# - Win7:  http://localhost:8007

# Stop all when done
./winctl.sh stop win11 win10 win7
```

### Scenario 3: Run Legacy Software on Windows XP

```bash
# Start Windows XP
./winctl.sh start winxp

# Access via http://localhost:8005
# Login: docker / admin

# Transfer files via the Shared folder on desktop
```

### Scenario 4: Monitor Resource Usage

```bash
# See real-time stats for all running VMs
./winctl.sh stats

# Or use the dashboard
./winctl.sh monitor
```

### Scenario 5: Increase Resources for a VM

1. Stop the container:
   ```bash
   ./winctl.sh stop win11
   ```

2. Edit `.env.modern`:
   ```bash
   RAM_SIZE=16G
   CPU_CORES=8
   ```

3. Start again:
   ```bash
   ./winctl.sh start win11
   ```

### Scenario 6: Fresh Start (Reset VM)

```bash
# This destroys the container but keeps data
./winctl.sh rebuild win11

# For a complete reset, also delete the data:
rm -rf data/win11/*
./winctl.sh start win11
```

---

## Troubleshooting

### Container Won't Start

**Check prerequisites:**
```bash
./winctl.sh check
```

**Check logs:**
```bash
./winctl.sh logs win11
```

**Common issues:**
- KVM not accessible → Add user to kvm group
- Port already in use → Stop other containers or services
- Not enough disk space → Free up space or reduce DISK_SIZE

### Slow Performance

- Ensure KVM is working (hardware virtualization)
- Increase RAM_SIZE and CPU_CORES in env file
- Use RDP instead of web viewer for better performance

### Can't Connect via RDP

1. Wait for Windows to fully boot (check web viewer first)
2. RDP might be disabled in Windows → Enable via web viewer
3. Check firewall settings in Windows

### Web Viewer Not Loading

```bash
# Check if container is running
./winctl.sh status win11

# Check container logs
./winctl.sh logs win11

# Restart the container
./winctl.sh restart win11
```

### Cache Issues

Force refresh the status cache:
```bash
./winctl.sh refresh
```

---

## Tips & Tricks

### 1. Use Aliases

Add to your `~/.bashrc`:
```bash
alias wctl='./winctl.sh'
alias wstart='./winctl.sh start'
alias wstop='./winctl.sh stop'
alias wstatus='./winctl.sh status'
```

### 2. Quick Access Bookmarks

Bookmark your commonly used VMs:
- Windows 11: http://localhost:8011
- Windows 10: http://localhost:8010

### 3. File Sharing

Each VM has a "Shared" folder on the desktop that maps to the host. Use this to transfer files.

### 4. Snapshots via Data Backup

The VM disk is stored in `data/<version>/`. Back it up to create a snapshot:
```bash
./winctl.sh stop win11
cp -r data/win11 data/win11-backup
./winctl.sh start win11
```

### 5. Running Multiple VMs

Check your available resources before starting multiple VMs:
```bash
# Each modern VM needs 8GB RAM
# Each legacy VM needs 2GB RAM

# Example: Running win11 + win10 + winxp = 8+8+2 = 18GB RAM needed
```

### 6. Headless Operation

For servers, you can start VMs and access only via RDP:
```bash
./winctl.sh start win2022
# Connect via RDP to localhost:3322
```

---

## File Structure

```
.
├── winctl.sh              # Management script
├── .env.modern            # Modern systems config (8G RAM)
├── .env.legacy            # Legacy systems config (2G RAM)
├── compose/
│   ├── desktop/           # Win 11, 10, 8.1, 7
│   ├── legacy/            # Vista, XP, 2000
│   ├── server/            # Server 2003-2025
│   └── tiny/              # Tiny10, Tiny11
├── data/
│   ├── win11/             # Win11 VM storage
│   ├── win10/             # Win10 VM storage
│   └── ...                # Other VM storage
└── ~/.cache/winctl/
    └── status.json        # Status cache
```

---

## Getting Help

```bash
# Show all commands
./winctl.sh help

# Check system requirements
./winctl.sh check

# List all versions
./winctl.sh list
```

For issues, visit: https://github.com/dockur/windows/issues
