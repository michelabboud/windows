# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **dockur/windows** - a Docker container that runs Windows inside QEMU with KVM acceleration. It provides automatic Windows installation with ISO downloading, VirtIO driver injection, and unattended setup via answer files.

## Architecture

### Entry Point & Script Chain

The container starts via `/run/entry.sh` which sources scripts in sequence:
1. `start.sh` → `utils.sh` → `reset.sh` → `server.sh` → `define.sh` → `mido.sh` → `install.sh`
2. Then: `disk.sh` → `display.sh` → `network.sh` → `samba.sh` → `boot.sh` → `proc.sh` → `power.sh` → `memory.sh` → `config.sh` → `finish.sh`
3. Finally launches `qemu-system-x86_64` with constructed arguments

### Key Components

- **src/define.sh**: Version parsing, language mapping, and Windows edition detection. Maps user-friendly version strings (e.g., "11", "10l", "2022") to internal identifiers
- **src/mido.sh**: Microsoft ISO downloader - scrapes Microsoft's download portal to get direct ISO links
- **src/install.sh**: ISO extraction, image detection, driver injection, answer file customization, and ISO rebuilding using `wimlib-imagex` and `genisoimage`
- **src/samba.sh**: Configures Samba for host-guest file sharing (appears as "Shared" folder on desktop)
- **assets/*.xml**: Unattended answer files for different Windows versions

### Build System

- Base image: `qemux/qemu` (QEMU with web-based VNC viewer)
- VirtIO drivers downloaded at build time from `qemus/virtiso-whql`
- Multi-arch support: amd64 native, arm64 via `dockur/windows-arm`

## Commands

### Linting & Validation

```bash
# ShellCheck for all shell scripts
shellcheck -x --source-path=src src/*.sh

# Dockerfile linting
hadolint Dockerfile

# XML validation (answer files)
# Uses action-pack/valid-xml in CI
```

### Building

```bash
# Build Docker image locally
docker build -t windows .

# Build with version argument
docker build --build-arg VERSION_ARG=1.0 -t windows .
```

### Testing Locally

```bash
# Run container (requires KVM)
docker run -it --rm -e "VERSION=11" -p 8006:8006 --device=/dev/kvm --device=/dev/net/tun --cap-add NET_ADMIN -v "${PWD}/storage:/storage" windows

# Access web viewer at http://localhost:8006
```

## CI/CD

- **check.yml**: Runs on PRs - ShellCheck, Hadolint, XML/JSON/YAML validation
- **build.yml**: Manual trigger - builds multi-arch image, pushes to Docker Hub and GHCR
- **test.yml**: Runs check.yml on PRs

ShellCheck exclusions (from CI): SC1091, SC2001, SC2002, SC2034, SC2064, SC2153, SC2317, SC2028

## Key Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| VERSION | "11" | Windows version (11, 10, 10l, 2022, etc.) or ISO URL |
| LANGUAGE | "en" | Installation language |
| USERNAME | "Docker" | Windows username |
| PASSWORD | "admin" | Windows password |
| DISK_SIZE | "64G" | Virtual disk size |
| RAM_SIZE | "4G" | RAM allocation |
| CPU_CORES | "2" | CPU cores |
| MANUAL | "" | Set to "Y" for manual installation |

## Adding New Windows Versions

1. Add version aliases in `src/define.sh` `parseVersion()` function
2. Create answer file in `assets/` named `{version}.xml`
3. Add driver folder mapping in `src/install.sh` `addDriver()` function
