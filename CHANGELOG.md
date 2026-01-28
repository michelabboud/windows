# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-01-28

### Added
- **winctl.sh**: Management script for Windows Docker containers
  - 12 commands: start, stop, restart, status, logs, shell, stats, build, rebuild, list, inspect, monitor, check
  - Interactive menus for version selection
  - Prerequisites checking (Docker, Compose, KVM, TUN, memory, disk)
  - Color-coded output with professional table formatting
  - Safety confirmations for destructive operations
  - Support for all 22 Windows versions across 4 categories
- Multi-version compose structure with organized folders (`compose/`)
- Environment file configuration (`.env` / `.env.example`)
- Two resource profiles: modern (8G RAM, 4 CPU) and legacy (2G RAM, 2 CPU)
- Per-version data folders under `data/`
- Pre-configured compose files for all Windows versions:
  - Desktop: Win 11, 10, 8.1, 7 (with Enterprise variants)
  - Legacy: Vista, XP, 2000
  - Server: 2003, 2008, 2012, 2016, 2019, 2022, 2025
  - Tiny: Tiny11, Tiny10
- Unique port mappings for each version (no conflicts)
- CLAUDE.md for Claude Code guidance

### Changed
- Default storage location changed from `./windows` to `./data/`
- Compose files now use `env_file` for centralized configuration
- Restart policy changed from `always` to `unless-stopped`

### Resource Profiles

| Profile | RAM | CPU | Disk | Used By |
|---------|-----|-----|------|---------|
| Modern | 8G | 4 | 128G | Win 10/11, Server 2016+ |
| Legacy | 2G | 2 | 32G | Win 7/8, Vista, XP, 2000, Server 2003-2012, Tiny |
