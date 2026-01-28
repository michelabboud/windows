#!/usr/bin/env bash
#
# winctl.sh - Windows Docker Container Management Script
# Manage Windows Docker containers with ease
#
# Usage: ./winctl.sh <command> [options]
#
set -Eeuo pipefail

# ==============================================================================
# METADATA
# ==============================================================================

readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="winctl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Cache settings
readonly CACHE_DIR="${HOME}/.cache/winctl"
readonly CACHE_FILE="${CACHE_DIR}/status.json"
readonly CACHE_MAX_AGE=$((7 * 24 * 60 * 60))  # 7 days in seconds

# ==============================================================================
# COLORS & TERMINAL DETECTION
# ==============================================================================

if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[0;33m'
    readonly BLUE='\033[0;34m'
    readonly MAGENTA='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[0;37m'
    readonly BOLD='\033[1m'
    readonly DIM='\033[2m'
    readonly RESET='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly MAGENTA=''
    readonly CYAN=''
    readonly WHITE=''
    readonly BOLD=''
    readonly DIM=''
    readonly RESET=''
fi

# ==============================================================================
# VERSION DATA
# ==============================================================================

# All supported versions
readonly ALL_VERSIONS=(
    win11 win11e win11l win10 win10e win10l
    win81 win81e win7 win7e
    vista winxp win2k
    win2025 win2022 win2019 win2016 win2012 win2008 win2003
    tiny11 tiny10
)

# Port mappings (web)
declare -A VERSION_PORTS_WEB=(
    ["win11"]=8011 ["win11e"]=8012 ["win11l"]=8013
    ["win10"]=8010 ["win10e"]=8014 ["win10l"]=8015
    ["win81"]=8008 ["win81e"]=8081
    ["win7"]=8007 ["win7e"]=8071
    ["vista"]=8006 ["winxp"]=8005 ["win2k"]=8000
    ["win2025"]=8025 ["win2022"]=8022 ["win2019"]=8019 ["win2016"]=8016
    ["win2012"]=8112 ["win2008"]=8108 ["win2003"]=8003
    ["tiny11"]=8111 ["tiny10"]=8110
)

# Port mappings (RDP)
declare -A VERSION_PORTS_RDP=(
    ["win11"]=3311 ["win11e"]=3312 ["win11l"]=3313
    ["win10"]=3310 ["win10e"]=3314 ["win10l"]=3315
    ["win81"]=3308 ["win81e"]=3381
    ["win7"]=3307 ["win7e"]=3371
    ["vista"]=3306 ["winxp"]=3305 ["win2k"]=3300
    ["win2025"]=3325 ["win2022"]=3322 ["win2019"]=3319 ["win2016"]=3316
    ["win2012"]=3212 ["win2008"]=3208 ["win2003"]=3303
    ["tiny11"]=3111 ["tiny10"]=3110
)

# Categories
declare -A VERSION_CATEGORIES=(
    ["win11"]="desktop" ["win11e"]="desktop" ["win11l"]="desktop"
    ["win10"]="desktop" ["win10e"]="desktop" ["win10l"]="desktop"
    ["win81"]="desktop" ["win81e"]="desktop"
    ["win7"]="desktop" ["win7e"]="desktop"
    ["vista"]="legacy" ["winxp"]="legacy" ["win2k"]="legacy"
    ["win2025"]="server" ["win2022"]="server" ["win2019"]="server" ["win2016"]="server"
    ["win2012"]="server" ["win2008"]="server" ["win2003"]="server"
    ["tiny11"]="tiny" ["tiny10"]="tiny"
)

# Compose files
declare -A VERSION_COMPOSE_FILES=(
    ["win11"]="compose/desktop/win11.yml" ["win11e"]="compose/desktop/win11.yml" ["win11l"]="compose/desktop/win11.yml"
    ["win10"]="compose/desktop/win10.yml" ["win10e"]="compose/desktop/win10.yml" ["win10l"]="compose/desktop/win10.yml"
    ["win81"]="compose/desktop/win8.yml" ["win81e"]="compose/desktop/win8.yml"
    ["win7"]="compose/desktop/win7.yml" ["win7e"]="compose/desktop/win7.yml"
    ["vista"]="compose/legacy/vista.yml" ["winxp"]="compose/legacy/winxp.yml" ["win2k"]="compose/legacy/win2k.yml"
    ["win2025"]="compose/server/win2025.yml" ["win2022"]="compose/server/win2022.yml"
    ["win2019"]="compose/server/win2019.yml" ["win2016"]="compose/server/win2016.yml"
    ["win2012"]="compose/server/win2012.yml" ["win2008"]="compose/server/win2008.yml" ["win2003"]="compose/server/win2003.yml"
    ["tiny11"]="compose/tiny/tiny11.yml" ["tiny10"]="compose/tiny/tiny10.yml"
)

# Display names
declare -A VERSION_DISPLAY_NAMES=(
    ["win11"]="Windows 11 Pro" ["win11e"]="Windows 11 Enterprise" ["win11l"]="Windows 11 LTSC"
    ["win10"]="Windows 10 Pro" ["win10e"]="Windows 10 Enterprise" ["win10l"]="Windows 10 LTSC"
    ["win81"]="Windows 8.1 Pro" ["win81e"]="Windows 8.1 Enterprise"
    ["win7"]="Windows 7 Ultimate" ["win7e"]="Windows 7 Enterprise"
    ["vista"]="Windows Vista Ultimate" ["winxp"]="Windows XP Professional" ["win2k"]="Windows 2000 Professional"
    ["win2025"]="Windows Server 2025" ["win2022"]="Windows Server 2022"
    ["win2019"]="Windows Server 2019" ["win2016"]="Windows Server 2016"
    ["win2012"]="Windows Server 2012 R2" ["win2008"]="Windows Server 2008 R2" ["win2003"]="Windows Server 2003"
    ["tiny11"]="Tiny11" ["tiny10"]="Tiny10"
)

# Resource type (modern = high resources, legacy = low resources)
declare -A VERSION_RESOURCE_TYPE=(
    ["win11"]="modern" ["win11e"]="modern" ["win11l"]="modern"
    ["win10"]="modern" ["win10e"]="modern" ["win10l"]="modern"
    ["win81"]="legacy" ["win81e"]="legacy"
    ["win7"]="legacy" ["win7e"]="legacy"
    ["vista"]="legacy" ["winxp"]="legacy" ["win2k"]="legacy"
    ["win2025"]="modern" ["win2022"]="modern" ["win2019"]="modern" ["win2016"]="modern"
    ["win2012"]="legacy" ["win2008"]="legacy" ["win2003"]="legacy"
    ["tiny11"]="legacy" ["tiny10"]="legacy"
)

# Resource requirements
readonly MODERN_RAM_GB=8
readonly MODERN_DISK_GB=128
readonly LEGACY_RAM_GB=2
readonly LEGACY_DISK_GB=32

# ==============================================================================
# OUTPUT HELPERS
# ==============================================================================

info() {
    echo -e "${BLUE}[INFO]${RESET} $*"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $*" >&2
}

die() {
    error "$@"
    exit 1
}

header() {
    echo ""
    echo -e "${BOLD}${CYAN}$*${RESET}"
    echo -e "${DIM}$(printf '─%.0s' {1..60})${RESET}"
}

# Print a formatted table row
table_row() {
    local version="$1"
    local name="$2"
    local status="$3"
    local web="$4"
    local rdp="$5"

    local status_color
    case "$status" in
        running) status_color="${GREEN}" ;;
        stopped|exited) status_color="${RED}" ;;
        *) status_color="${YELLOW}" ;;
    esac

    printf "  ${BOLD}%-12s${RESET} %-26s ${status_color}%-10s${RESET} %-8s %-8s\n" \
        "$version" "$name" "$status" "$web" "$rdp"
}

table_header() {
    echo ""
    printf "  ${BOLD}${DIM}%-12s %-26s %-10s %-8s %-8s${RESET}\n" \
        "VERSION" "NAME" "STATUS" "WEB" "RDP"
    echo -e "  ${DIM}$(printf '─%.0s' {1..66})${RESET}"
}

# ==============================================================================
# PREREQUISITES CHECKS
# ==============================================================================

check_docker() {
    if ! command -v docker &>/dev/null; then
        error "Docker is not installed"
        echo "  Install Docker: https://docs.docker.com/get-docker/"
        return 1
    fi

    if ! docker info &>/dev/null; then
        error "Docker daemon is not running"
        echo "  Start Docker: sudo systemctl start docker"
        return 1
    fi

    success "Docker is available"
    return 0
}

check_compose() {
    if docker compose version &>/dev/null; then
        success "Docker Compose plugin is available"
        return 0
    elif command -v docker-compose &>/dev/null; then
        success "Docker Compose standalone is available"
        return 0
    else
        error "Docker Compose is not installed"
        echo "  Install: https://docs.docker.com/compose/install/"
        return 1
    fi
}

check_kvm() {
    if [[ ! -e /dev/kvm ]]; then
        error "KVM device not found (/dev/kvm)"
        echo "  Enable virtualization in BIOS or check nested virtualization"
        return 1
    fi

    if [[ ! -r /dev/kvm ]] || [[ ! -w /dev/kvm ]]; then
        error "KVM device not accessible"
        echo "  Fix: sudo usermod -aG kvm \$USER && newgrp kvm"
        return 1
    fi

    success "KVM is available"
    return 0
}

check_tun() {
    if [[ ! -e /dev/net/tun ]]; then
        warn "TUN device not found (/dev/net/tun) - networking may be limited"
        return 1
    fi

    success "TUN device is available"
    return 0
}

check_memory() {
    local required_gb="${1:-$MODERN_RAM_GB}"
    local available_kb
    available_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local available_gb=$((available_kb / 1024 / 1024))

    if ((available_gb < required_gb)); then
        warn "Low memory: ${available_gb}GB available (${required_gb}GB recommended)"
        return 1
    fi

    success "Memory OK: ${available_gb}GB available (${required_gb}GB needed)"
    return 0
}

check_disk() {
    local required_gb="${1:-$MODERN_DISK_GB}"
    local available_kb
    available_kb=$(df "$SCRIPT_DIR" | tail -1 | awk '{print $4}')
    local available_gb=$((available_kb / 1024 / 1024))

    if ((available_gb < required_gb)); then
        warn "Low disk space: ${available_gb}GB available (${required_gb}GB recommended)"
        return 1
    fi

    success "Disk space OK: ${available_gb}GB available (${required_gb}GB needed)"
    return 0
}

run_all_checks() {
    header "Prerequisites Check"

    local failed=0

    check_docker || ((failed++))
    check_compose || ((failed++))
    check_kvm || ((failed++))
    check_tun || true  # Warning only
    check_memory || true  # Warning only
    check_disk || true  # Warning only

    echo ""
    if ((failed > 0)); then
        error "Some critical checks failed. Please fix the issues above."
        return 1
    else
        success "All critical prerequisites passed!"
        return 0
    fi
}

# ==============================================================================
# DOCKER HELPERS
# ==============================================================================

# Get the compose command (plugin vs standalone)
compose_cmd() {
    if docker compose version &>/dev/null; then
        echo "docker compose"
    else
        echo "docker-compose"
    fi
}

# ==============================================================================
# STATUS CACHE (JSON file-based with auto-refresh)
# ==============================================================================

# In-memory cache (loaded from JSON)
declare -A _STATUS_CACHE=()
_STATUS_CACHE_VALID=false
_STATUS_CACHE_TIMESTAMP=0

# Ensure cache directory exists
ensure_cache_dir() {
    [[ -d "$CACHE_DIR" ]] || mkdir -p "$CACHE_DIR"
}

# Get cache file age in seconds (returns large number if file doesn't exist)
get_cache_age() {
    if [[ -f "$CACHE_FILE" ]]; then
        local file_time current_time
        file_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
        current_time=$(date +%s)
        echo $((current_time - file_time))
    else
        echo 999999999
    fi
}

# Check if cache needs refresh (age > max age)
cache_needs_refresh() {
    local age
    age=$(get_cache_age)
    ((age > CACHE_MAX_AGE))
}

# Write status cache to JSON file
write_cache_file() {
    ensure_cache_dir
    local timestamp
    timestamp=$(date +%s)

    # Build JSON manually (no jq dependency)
    {
        echo "{"
        echo "  \"timestamp\": $timestamp,"
        echo "  \"containers\": {"
        local first=true
        for name in "${!_STATUS_CACHE[@]}"; do
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo ","
            fi
            printf '    "%s": "%s"' "$name" "${_STATUS_CACHE[$name]}"
        done
        echo ""
        echo "  }"
        echo "}"
    } > "$CACHE_FILE"
}

# Read status cache from JSON file
read_cache_file() {
    if [[ ! -f "$CACHE_FILE" ]]; then
        return 1
    fi

    _STATUS_CACHE=()
    _STATUS_CACHE_TIMESTAMP=0

    # Parse JSON manually (no jq dependency)
    local in_containers=false
    while IFS= read -r line; do
        # Extract timestamp
        if [[ "$line" =~ \"timestamp\":[[:space:]]*([0-9]+) ]]; then
            _STATUS_CACHE_TIMESTAMP="${BASH_REMATCH[1]}"
        fi
        # Track when we're in containers section
        if [[ "$line" =~ \"containers\" ]]; then
            in_containers=true
            continue
        fi
        # Parse container entries
        if [[ "$in_containers" == "true" && "$line" =~ \"([^\"]+)\":[[:space:]]*\"([^\"]+)\" ]]; then
            local name="${BASH_REMATCH[1]}"
            local state="${BASH_REMATCH[2]}"
            _STATUS_CACHE["$name"]="$state"
        fi
    done < "$CACHE_FILE"

    return 0
}

# Validate cache by spot-checking a running container still exists
validate_cache() {
    # If cache shows a container as running, verify it still exists
    for name in "${!_STATUS_CACHE[@]}"; do
        if [[ "${_STATUS_CACHE[$name]}" == "running" ]]; then
            # Quick check if this container exists
            if ! docker ps -q --filter "name=^${name}$" 2>/dev/null | grep -q .; then
                return 1  # Cache is stale
            fi
            return 0  # Found a valid running container
        fi
    done
    return 0  # No running containers to validate
}

# Refresh the status cache from Docker and save to file
refresh_status_cache() {
    local force="${1:-false}"

    # Try to load from file cache first (unless forced)
    if [[ "$force" != "true" && "$_STATUS_CACHE_VALID" != "true" ]]; then
        if read_cache_file; then
            # Check if cache is still valid (not too old)
            if ! cache_needs_refresh; then
                # Validate cache data
                if validate_cache; then
                    _STATUS_CACHE_VALID=true
                    return 0
                fi
            fi
        fi
    fi

    # Fetch fresh data from Docker
    _STATUS_CACHE=()
    local line
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local name state
            name="${line%%:*}"
            state="${line#*:}"
            _STATUS_CACHE["$name"]="$state"
        fi
    done < <(docker ps -a --format '{{.Names}}:{{.State}}' 2>/dev/null)
    _STATUS_CACHE_VALID=true

    # Save to file
    write_cache_file
}

# Force refresh the cache (called after start/stop/restart operations)
invalidate_cache() {
    _STATUS_CACHE_VALID=false
    refresh_status_cache true
}

# Check if a container is running
is_running() {
    local version="$1"
    if [[ "$_STATUS_CACHE_VALID" == "true" ]]; then
        [[ "${_STATUS_CACHE[$version]:-}" == "running" ]]
    else
        docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${version}$"
    fi
}

# Check if a container exists (running or stopped)
container_exists() {
    local version="$1"
    if [[ "$_STATUS_CACHE_VALID" == "true" ]]; then
        [[ -n "${_STATUS_CACHE[$version]:-}" ]]
    else
        docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${version}$"
    fi
}

# Get container status
get_status() {
    local version="$1"
    if [[ "$_STATUS_CACHE_VALID" == "true" ]]; then
        echo "${_STATUS_CACHE[$version]:-not created}"
    else
        local status
        status=$(docker ps -a --filter "name=^${version}$" --format '{{.State}}' 2>/dev/null)
        echo "${status:-not created}"
    fi
}

# Get compose file path for version
get_compose_file() {
    local version="$1"
    local file="${VERSION_COMPOSE_FILES[$version]:-}"
    if [[ -z "$file" ]]; then
        die "Unknown version: $version"
    fi
    echo "$SCRIPT_DIR/$file"
}

# Validate version
validate_version() {
    local version="$1"
    if [[ -z "${VERSION_COMPOSE_FILES[$version]:-}" ]]; then
        error "Unknown version: $version"
        echo "  Run '${SCRIPT_NAME} list' to see available versions"
        return 1
    fi
    return 0
}

# Run compose command for a version
run_compose() {
    local version="$1"
    shift
    local compose_file
    compose_file=$(get_compose_file "$version")

    cd "$SCRIPT_DIR"
    $(compose_cmd) -f "$compose_file" "$@"
}

# ==============================================================================
# INTERACTIVE MENU
# ==============================================================================

# Get versions by category
get_versions_by_category() {
    local category="$1"
    local versions=()
    for v in "${ALL_VERSIONS[@]}"; do
        if [[ "${VERSION_CATEGORIES[$v]}" == "$category" ]]; then
            versions+=("$v")
        fi
    done
    echo "${versions[*]}"
}

# Show category menu (prompts to stderr, result to stdout)
select_category() {
    {
        header "Select Category"
        echo ""
        echo "  ${BOLD}1${RESET}) Desktop (Win 11, 10, 8.1, 7)"
        echo "  ${BOLD}2${RESET}) Legacy (Vista, XP, 2000)"
        echo "  ${BOLD}3${RESET}) Server (2025, 2022, 2019, 2016, 2012, 2008, 2003)"
        echo "  ${BOLD}4${RESET}) Tiny (Tiny11, Tiny10)"
        echo "  ${BOLD}5${RESET}) All versions"
        echo "  ${BOLD}6${RESET}) Select individual versions"
        echo ""
        echo -n "  Select [1-6]: "
    } >&2

    local choice
    read -r choice </dev/tty

    case "$choice" in
        1) echo "desktop" ;;
        2) echo "legacy" ;;
        3) echo "server" ;;
        4) echo "tiny" ;;
        5) echo "all" ;;
        6) echo "individual" ;;
        *) echo "" ;;
    esac
}

# Show version selection menu (prompts to stderr, result to stdout)
select_versions() {
    local category="$1"
    local versions=()

    if [[ "$category" == "all" ]]; then
        versions=("${ALL_VERSIONS[@]}")
    elif [[ "$category" == "individual" ]]; then
        versions=("${ALL_VERSIONS[@]}")
    else
        IFS=' ' read -ra versions <<< "$(get_versions_by_category "$category")"
    fi

    if [[ ${#versions[@]} -eq 0 ]]; then
        error "No versions found for category: $category"
        return 1
    fi

    # Fetch all container statuses in one call
    refresh_status_cache

    {
        header "Select Version(s)"
        echo ""

        local i=1
        for v in "${versions[@]}"; do
            local status=""
            if is_running "$v"; then
                status="${GREEN}[running]${RESET}"
            elif container_exists "$v"; then
                status="${YELLOW}[stopped]${RESET}"
            fi
            printf "  ${BOLD}%2d${RESET}) %-10s %-28s %s\n" "$i" "$v" "${VERSION_DISPLAY_NAMES[$v]}" "$status"
            ((i++))
        done

        echo ""
        echo "  ${BOLD} a${RESET}) Select all"
        echo "  ${BOLD} q${RESET}) Cancel"
        echo ""
        echo -n "  Select (numbers separated by spaces, or 'a' for all): "
    } >&2

    local input
    read -r input </dev/tty

    if [[ "$input" == "q" ]] || [[ -z "$input" ]]; then
        return 1
    fi

    if [[ "$input" == "a" ]]; then
        echo "${versions[*]}"
        return 0
    fi

    local selected=()
    for num in $input; do
        if [[ "$num" =~ ^[0-9]+$ ]] && ((num >= 1 && num <= ${#versions[@]})); then
            selected+=("${versions[$((num-1))]}")
        fi
    done

    if [[ ${#selected[@]} -eq 0 ]]; then
        return 1
    fi

    echo "${selected[*]}"
}

# Interactive version selection
interactive_select() {
    local category
    category=$(select_category)

    if [[ -z "$category" ]]; then
        error "Invalid selection"
        return 1
    fi

    local selected
    if ! selected=$(select_versions "$category"); then
        error "No versions selected"
        return 1
    fi

    echo "$selected"
}

# ==============================================================================
# COMMANDS
# ==============================================================================

cmd_start() {
    local versions=("$@")

    # Interactive selection if no versions specified
    if [[ ${#versions[@]} -eq 0 ]]; then
        local selected
        if ! selected=$(interactive_select); then
            exit 1
        fi
        IFS=' ' read -ra versions <<< "$selected"
    fi

    # Validate all versions first
    for v in "${versions[@]}"; do
        validate_version "$v" || exit 1
    done

    # Run prerequisite checks
    check_docker || exit 1
    check_kvm || exit 1

    for v in "${versions[@]}"; do
        header "Starting ${VERSION_DISPLAY_NAMES[$v]} ($v)"

        # Check resources
        local resource_type="${VERSION_RESOURCE_TYPE[$v]}"
        if [[ "$resource_type" == "modern" ]]; then
            check_memory "$MODERN_RAM_GB" || true
            check_disk "$MODERN_DISK_GB" || true
        else
            check_memory "$LEGACY_RAM_GB" || true
            check_disk "$LEGACY_DISK_GB" || true
        fi

        if is_running "$v"; then
            info "$v is already running"
        else
            info "Starting $v..."
            if run_compose "$v" up -d "$v"; then
                success "$v started successfully"
            else
                error "Failed to start $v"
                continue
            fi
        fi

        # Show connection info
        echo ""
        echo -e "  ${BOLD}Connection Details:${RESET}"
        echo -e "    → Web Viewer: ${CYAN}http://localhost:${VERSION_PORTS_WEB[$v]}${RESET}"
        echo -e "    → RDP:        ${CYAN}localhost:${VERSION_PORTS_RDP[$v]}${RESET}"
        echo ""
    done

    # Refresh cache after state changes
    invalidate_cache
}

cmd_stop() {
    local versions=("$@")

    # Interactive selection if no versions specified
    if [[ ${#versions[@]} -eq 0 ]]; then
        local selected
        if ! selected=$(interactive_select); then
            exit 1
        fi
        IFS=' ' read -ra versions <<< "$selected"
    fi

    # Validate all versions first
    for v in "${versions[@]}"; do
        validate_version "$v" || exit 1
    done

    # Show confirmation
    header "Stopping Containers"
    echo ""
    echo "  The following containers will be stopped:"
    for v in "${versions[@]}"; do
        local status
        if is_running "$v"; then
            status="${GREEN}running${RESET}"
        else
            status="${YELLOW}not running${RESET}"
        fi
        echo -e "    • $v (${VERSION_DISPLAY_NAMES[$v]}) - $status"
    done
    echo ""
    echo -n "  Continue? [y/N]: "

    local confirm
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Cancelled"
        return 0
    fi

    for v in "${versions[@]}"; do
        if ! is_running "$v" && ! container_exists "$v"; then
            info "$v is not running"
            continue
        fi

        info "Stopping $v (grace period: 2 minutes)..."
        if run_compose "$v" stop "$v"; then
            success "$v stopped"
        else
            error "Failed to stop $v"
        fi
    done

    # Refresh cache after state changes
    invalidate_cache
}

cmd_restart() {
    local versions=("$@")

    # Interactive selection if no versions specified
    if [[ ${#versions[@]} -eq 0 ]]; then
        local selected
        if ! selected=$(interactive_select); then
            exit 1
        fi
        IFS=' ' read -ra versions <<< "$selected"
    fi

    # Validate all versions first
    for v in "${versions[@]}"; do
        validate_version "$v" || exit 1
    done

    for v in "${versions[@]}"; do
        header "Restarting ${VERSION_DISPLAY_NAMES[$v]} ($v)"

        info "Restarting $v..."
        if run_compose "$v" restart "$v"; then
            success "$v restarted"
            echo ""
            echo -e "  ${BOLD}Connection Details:${RESET}"
            echo -e "    → Web Viewer: ${CYAN}http://localhost:${VERSION_PORTS_WEB[$v]}${RESET}"
            echo -e "    → RDP:        ${CYAN}localhost:${VERSION_PORTS_RDP[$v]}${RESET}"
            echo ""
        else
            error "Failed to restart $v"
        fi
    done

    # Refresh cache after state changes
    invalidate_cache
}

cmd_status() {
    local versions=("$@")

    # Show all if no versions specified
    if [[ ${#versions[@]} -eq 0 ]]; then
        versions=("${ALL_VERSIONS[@]}")
    fi

    table_header

    for v in "${versions[@]}"; do
        if ! validate_version "$v" 2>/dev/null; then
            continue
        fi

        local status
        status=$(get_status "$v")
        table_row "$v" "${VERSION_DISPLAY_NAMES[$v]}" "$status" "${VERSION_PORTS_WEB[$v]}" "${VERSION_PORTS_RDP[$v]}"
    done
    echo ""
}

cmd_logs() {
    local version="${1:-}"
    local follow="${2:-}"

    if [[ -z "$version" ]]; then
        die "Usage: ${SCRIPT_NAME} logs <version> [-f]"
    fi

    validate_version "$version" || exit 1

    local args=()
    if [[ "$follow" == "-f" ]]; then
        args+=("--follow")
    fi

    info "Showing logs for $version..."
    run_compose "$version" logs "${args[@]}" "$version"
}

cmd_shell() {
    local version="${1:-}"

    if [[ -z "$version" ]]; then
        die "Usage: ${SCRIPT_NAME} shell <version>"
    fi

    validate_version "$version" || exit 1

    if ! is_running "$version"; then
        die "$version is not running"
    fi

    info "Opening shell in $version..."
    docker exec -it "$version" /bin/bash
}

cmd_stats() {
    local versions=("$@")

    # Get running containers if no versions specified
    if [[ ${#versions[@]} -eq 0 ]]; then
        local running=()
        for v in "${ALL_VERSIONS[@]}"; do
            if is_running "$v"; then
                running+=("$v")
            fi
        done
        if [[ ${#running[@]} -eq 0 ]]; then
            die "No containers are running"
        fi
        versions=("${running[@]}")
    fi

    # Validate versions
    local valid_running=()
    for v in "${versions[@]}"; do
        if validate_version "$v" 2>/dev/null && is_running "$v"; then
            valid_running+=("$v")
        fi
    done

    if [[ ${#valid_running[@]} -eq 0 ]]; then
        die "None of the specified containers are running"
    fi

    info "Showing stats for: ${valid_running[*]}"
    docker stats "${valid_running[@]}"
}

cmd_build() {
    header "Building Docker Image"

    check_docker || exit 1

    info "Building dockurr/windows image locally..."
    cd "$SCRIPT_DIR"

    if docker build -t dockurr/windows .; then
        success "Image built successfully"
    else
        die "Build failed"
    fi
}

cmd_rebuild() {
    local versions=("$@")

    # Interactive selection if no versions specified
    if [[ ${#versions[@]} -eq 0 ]]; then
        local selected
        if ! selected=$(interactive_select); then
            exit 1
        fi
        IFS=' ' read -ra versions <<< "$selected"
    fi

    # Validate all versions first
    for v in "${versions[@]}"; do
        validate_version "$v" || exit 1
    done

    # Show warning
    header "⚠️  Rebuild Containers"
    echo ""
    echo -e "  ${RED}${BOLD}WARNING: This will destroy and recreate the following containers.${RESET}"
    echo -e "  ${RED}Data in /storage volumes will be preserved.${RESET}"
    echo ""
    for v in "${versions[@]}"; do
        echo "    • $v (${VERSION_DISPLAY_NAMES[$v]})"
    done
    echo ""
    echo -n "  Type 'yes' to confirm: "

    local confirm
    read -r confirm
    if [[ "$confirm" != "yes" ]]; then
        info "Cancelled"
        return 0
    fi

    for v in "${versions[@]}"; do
        header "Rebuilding $v"

        info "Stopping and removing $v..."
        run_compose "$v" down "$v" 2>/dev/null || true

        info "Recreating $v..."
        if run_compose "$v" up -d "$v"; then
            success "$v rebuilt successfully"
            echo ""
            echo -e "  ${BOLD}Connection Details:${RESET}"
            echo -e "    → Web Viewer: ${CYAN}http://localhost:${VERSION_PORTS_WEB[$v]}${RESET}"
            echo -e "    → RDP:        ${CYAN}localhost:${VERSION_PORTS_RDP[$v]}${RESET}"
            echo ""
        else
            error "Failed to rebuild $v"
        fi
    done

    # Refresh cache after state changes
    invalidate_cache
}

cmd_list() {
    local category="${1:-all}"

    header "Available Windows Versions"

    local categories=()
    case "$category" in
        desktop) categories=("desktop") ;;
        legacy) categories=("legacy") ;;
        server) categories=("server") ;;
        tiny) categories=("tiny") ;;
        all) categories=("desktop" "legacy" "server" "tiny") ;;
        *)
            die "Unknown category: $category. Use: desktop, legacy, server, tiny, or all"
            ;;
    esac

    for cat in "${categories[@]}"; do
        echo ""
        local cat_upper
        cat_upper=$(echo "$cat" | tr '[:lower:]' '[:upper:]')
        echo -e "  ${BOLD}${cat_upper}${RESET}"
        echo -e "  ${DIM}$(printf '─%.0s' {1..50})${RESET}"

        for v in "${ALL_VERSIONS[@]}"; do
            if [[ "${VERSION_CATEGORIES[$v]}" == "$cat" ]]; then
                local status=""
                if is_running "$v"; then
                    status="${GREEN}[running]${RESET}"
                elif container_exists "$v"; then
                    status="${YELLOW}[stopped]${RESET}"
                fi
                local resource_tag
                if [[ "${VERSION_RESOURCE_TYPE[$v]}" == "modern" ]]; then
                    resource_tag="${CYAN}(8G RAM)${RESET}"
                else
                    resource_tag="${DIM}(2G RAM)${RESET}"
                fi
                printf "    %-10s %-28s %s %s\n" "$v" "${VERSION_DISPLAY_NAMES[$v]}" "$resource_tag" "$status"
            fi
        done
    done
    echo ""
}

cmd_inspect() {
    local version="${1:-}"

    if [[ -z "$version" ]]; then
        die "Usage: ${SCRIPT_NAME} inspect <version>"
    fi

    validate_version "$version" || exit 1

    header "Container Details: $version"
    echo ""
    echo -e "  ${BOLD}Version:${RESET}      $version"
    echo -e "  ${BOLD}Name:${RESET}         ${VERSION_DISPLAY_NAMES[$version]}"
    echo -e "  ${BOLD}Category:${RESET}     ${VERSION_CATEGORIES[$version]}"
    echo -e "  ${BOLD}Status:${RESET}       $(get_status "$version")"
    echo -e "  ${BOLD}Web Port:${RESET}     ${VERSION_PORTS_WEB[$version]}"
    echo -e "  ${BOLD}RDP Port:${RESET}     ${VERSION_PORTS_RDP[$version]}"
    echo -e "  ${BOLD}Resources:${RESET}    ${VERSION_RESOURCE_TYPE[$version]}"
    echo -e "  ${BOLD}Compose:${RESET}      ${VERSION_COMPOSE_FILES[$version]}"
    echo ""

    if container_exists "$version"; then
        echo -e "  ${BOLD}Docker Info:${RESET}"
        docker inspect "$version" --format '
    Image:       {{.Config.Image}}
    Created:     {{.Created}}
    IP Address:  {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}
    Mounts:      {{range .Mounts}}{{.Source}} -> {{.Destination}}
                 {{end}}' 2>/dev/null || true
    fi
    echo ""
}

cmd_monitor() {
    local interval="${1:-5}"

    if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
        die "Interval must be a number (seconds)"
    fi

    header "Real-time Monitor (refresh: ${interval}s)"
    echo "  Press Ctrl+C to exit"
    echo ""

    while true; do
        clear
        echo -e "${BOLD}${CYAN}Windows Container Monitor${RESET} - $(date '+%Y-%m-%d %H:%M:%S')"
        echo -e "${DIM}$(printf '─%.0s' {1..70})${RESET}"

        local running_count=0
        local stopped_count=0
        local total_count=0

        table_header

        for v in "${ALL_VERSIONS[@]}"; do
            local status
            status=$(get_status "$v")
            if [[ "$status" != "not created" ]]; then
                ((total_count++))
                if [[ "$status" == "running" ]]; then
                    ((running_count++))
                else
                    ((stopped_count++))
                fi
                table_row "$v" "${VERSION_DISPLAY_NAMES[$v]}" "$status" "${VERSION_PORTS_WEB[$v]}" "${VERSION_PORTS_RDP[$v]}"
            fi
        done

        if [[ $total_count -eq 0 ]]; then
            echo -e "  ${DIM}No containers found${RESET}"
        fi

        echo ""
        echo -e "  ${BOLD}Summary:${RESET} ${GREEN}$running_count running${RESET}, ${RED}$stopped_count stopped${RESET}, $total_count total"
        echo ""
        echo -e "  ${DIM}Refreshing in ${interval}s... (Ctrl+C to exit)${RESET}"

        sleep "$interval"
    done
}

cmd_check() {
    run_all_checks
}

cmd_refresh() {
    header "Refreshing Status Cache"

    info "Fetching container statuses from Docker..."
    refresh_status_cache true

    local count=${#_STATUS_CACHE[@]}
    success "Cache refreshed (${count} containers found)"

    # Show cache info
    local age
    age=$(get_cache_age)
    echo ""
    echo -e "  ${BOLD}Cache Info:${RESET}"
    echo -e "    → File:     ${CYAN}${CACHE_FILE}${RESET}"
    echo -e "    → Age:      ${age} seconds"
    echo -e "    → Max Age:  ${CACHE_MAX_AGE} seconds (7 days)"
    echo ""

    # Show summary
    local cnt_running=0 cnt_stopped=0 cnt_other=0
    for state in "${_STATUS_CACHE[@]}"; do
        case "$state" in
            running) ((cnt_running++)) || true ;;
            exited)  ((cnt_stopped++)) || true ;;
            *)       ((cnt_other++)) || true ;;
        esac
    done
    echo -e "  ${BOLD}Containers:${RESET} ${GREEN}${cnt_running} running${RESET}, ${RED}${cnt_stopped} stopped${RESET}, ${DIM}${cnt_other} other${RESET}"
    echo ""
}

# ==============================================================================
# HELP
# ==============================================================================

show_usage() {
    printf '%b\n' "${BOLD}${SCRIPT_NAME}${RESET} v${SCRIPT_VERSION} - Windows Docker Container Management"
    printf '\n'
    printf '%b\n' "${BOLD}USAGE${RESET}"
    printf '    %s <command> [options]\n' "${SCRIPT_NAME}"
    printf '\n'
    printf '%b\n' "${BOLD}COMMANDS${RESET}"
    printf '    %b [version...]     Start container(s), interactive if no version\n' "${BOLD}start${RESET}"
    printf '    %b [version...]      Stop container(s) with 2-min grace period\n' "${BOLD}stop${RESET}"
    printf '    %b [version...]   Restart container(s)\n' "${BOLD}restart${RESET}"
    printf '    %b [version...]    Show status of container(s)\n' "${BOLD}status${RESET}"
    printf '    %b <version> [-f]    View container logs (-f to follow)\n' "${BOLD}logs${RESET}"
    printf '    %b <version>        Open bash shell in container\n' "${BOLD}shell${RESET}"
    printf '    %b [version...]     Show real-time resource usage\n' "${BOLD}stats${RESET}"
    printf '    %b                  Build Docker image locally\n' "${BOLD}build${RESET}"
    printf '    %b [version...]   Destroy and recreate container(s)\n' "${BOLD}rebuild${RESET}"
    printf '    %b [category]        List versions (desktop/legacy/server/tiny/all)\n' "${BOLD}list${RESET}"
    printf '    %b <version>      Show detailed container info\n' "${BOLD}inspect${RESET}"
    printf '    %b [interval]     Real-time dashboard (default: 5s refresh)\n' "${BOLD}monitor${RESET}"
    printf '    %b                  Run prerequisites check\n' "${BOLD}check${RESET}"
    printf '    %b                Force refresh status cache\n' "${BOLD}refresh${RESET}"
    printf '    %b                   Show this help message\n' "${BOLD}help${RESET}"
    printf '\n'
    printf '%b\n' "${BOLD}CATEGORIES${RESET}"
    printf '    desktop    Win 11/10/8.1/7 (Pro, Enterprise, LTSC variants)\n'
    printf '    legacy     Vista, XP, 2000\n'
    printf '    server     Server 2025/2022/2019/2016/2012/2008/2003\n'
    printf '    tiny       Tiny11, Tiny10\n'
    printf '\n'
    printf '%b\n' "${BOLD}EXAMPLES${RESET}"
    printf '    %s start                   # Interactive menu\n' "${SCRIPT_NAME}"
    printf '    %s start win11             # Start Windows 11\n' "${SCRIPT_NAME}"
    printf '    %s start win11 win10       # Start multiple\n' "${SCRIPT_NAME}"
    printf '    %s stop win11              # Stop with confirmation\n' "${SCRIPT_NAME}"
    printf '    %s status                  # Show all containers\n' "${SCRIPT_NAME}"
    printf '    %s logs win11 -f           # Follow logs\n' "${SCRIPT_NAME}"
    printf '    %s list desktop            # List desktop versions\n' "${SCRIPT_NAME}"
    printf '    %s monitor 10              # Dashboard with 10s refresh\n' "${SCRIPT_NAME}"
    printf '    %s rebuild win11           # Recreate container\n' "${SCRIPT_NAME}"
    printf '\n'
    printf '%b\n' "${BOLD}PORTS${RESET}"
    printf '    Each version has unique ports for Web UI and RDP access.\n'
    printf "    Run '%s list' to see port mappings.\n" "${SCRIPT_NAME}"
    printf '\n'
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    # Change to script directory
    cd "$SCRIPT_DIR"

    local command="${1:-}"
    shift || true

    case "$command" in
        start)      cmd_start "$@" ;;
        stop)       cmd_stop "$@" ;;
        restart)    cmd_restart "$@" ;;
        status)     cmd_status "$@" ;;
        logs)       cmd_logs "$@" ;;
        shell)      cmd_shell "$@" ;;
        stats)      cmd_stats "$@" ;;
        build)      cmd_build "$@" ;;
        rebuild)    cmd_rebuild "$@" ;;
        list)       cmd_list "$@" ;;
        inspect)    cmd_inspect "$@" ;;
        monitor)    cmd_monitor "$@" ;;
        check)      cmd_check "$@" ;;
        refresh)    cmd_refresh "$@" ;;
        help|--help|-h)
            show_usage
            ;;
        "")
            show_usage
            exit 1
            ;;
        *)
            error "Unknown command: $command"
            echo "Run '${SCRIPT_NAME} help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"
