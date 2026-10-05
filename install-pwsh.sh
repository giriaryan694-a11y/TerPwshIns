#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

# ============================================================
#  TerPwshIns
#  PowerShell installer for Termux
#  Dedicated Debian + PowerShell environment
#
#  Made By Aryan Giri | giriaryan694-a11y
# ============================================================

PWSH_CONTAINER="pwsh"
PWSH_DIR="/root/powershell"
PWSH_VERSION="${PWSH_VERSION:-7.6.6}"
PWSH_ARCHIVE="powershell-${PWSH_VERSION}-linux-arm64.tar.gz"
PWSH_URL="https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/${PWSH_ARCHIVE}"

WRAPPER="$PREFIX/bin/pwsh"

ACTION=""
SKIP_UPDATE="false"

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

RESET=$'\033[0m'
BOLD=$'\033[1m'
CYAN=$'\033[1;36m'
BLUE=$'\033[1;34m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[1;31m'
MAGENTA=$'\033[1;35m'

# ------------------------------------------------------------
# Banner
# ------------------------------------------------------------

banner() {
    clear 2>/dev/null || true

    printf '%s%s\n' "$CYAN" "$BOLD"

    cat <<'EOF'
╔══════════════════════════════════════════════════════╗
║                                                      ║
║                    TerPwshIns                        ║
║                                                      ║
║             PowerShell Installer for Termux          ║
║                                                      ║
║           Dedicated Debian + PowerShell Setup        ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF

    printf '%s\n' "$RESET"

    printf '%s%sMade By Aryan Giri | giriaryan694-a11y%s\n\n' \
        "$MAGENTA" "$BOLD" "$RESET"
}

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

info() {
    printf '%s[+]%s %s\n' "$BLUE" "$RESET" "$*"
}

success() {
    printf '%s[✓]%s %s\n' "$GREEN" "$RESET" "$*"
}

warn() {
    printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*"
}

error() {
    printf '%s[✗]%s %s\n' "$RED" "$RESET" "$*" >&2
}

# ------------------------------------------------------------
# Help
# ------------------------------------------------------------

show_help() {
    banner

    printf '%sUSAGE%s\n' "$BOLD" "$RESET"
    printf '    %s [OPTION] [FLAG]\n\n' "$(basename "$0")"

    printf '%sOPTIONS%s\n' "$BOLD" "$RESET"

    printf '    %s--install%s       Install PowerShell environment\n' \
        "$GREEN" "$RESET"

    printf '    %s--reinstall%s     Remove and reinstall PowerShell environment\n' \
        "$GREEN" "$RESET"

    printf '    %s--rm%s             Remove the dedicated pwsh environment\n' \
        "$RED" "$RESET"

    printf '    %s--skip-update%s   Skip repository updates when possible\n' \
        "$CYAN" "$RESET"

    printf '    %s--help%s          Show this help message\n\n' \
        "$YELLOW" "$RESET"

    printf '%sEXAMPLES%s\n' "$BOLD" "$RESET"

    printf '    ./%s --install\n' "$(basename "$0")"
    printf '    ./%s --install --skip-update\n' "$(basename "$0")"
    printf '    ./%s --reinstall\n' "$(basename "$0")"
    printf '    ./%s --reinstall --skip-update\n' "$(basename "$0")"
    printf '    ./%s --rm\n\n' "$(basename "$0")"

    printf '%sAFTER INSTALLATION%s\n' "$BOLD" "$RESET"

    printf '    Start PowerShell:\n'
    printf '        pwsh\n\n'

    printf '    Check PowerShell version:\n'
    printf '        pwsh -Command '\''$PSVersionTable'\''\n\n'

    printf '    Normal Debian remains separate:\n'
    printf '        proot-distro login debian\n\n'

    printf '%sENVIRONMENT%s\n' "$BOLD" "$RESET"

    printf '    PowerShell version: %s\n' "$PWSH_VERSION"
    printf '    Container:          %s\n' "$PWSH_CONTAINER"
    printf '    Termux binaries:    /termux/bin\n'
    printf '    Termux home:        /termux-home\n\n'

    printf '%sCREDITS%s\n' "$BOLD" "$RESET"

    printf '    Made By Aryan Giri | giriaryan694-a11y\n\n'
}

# ------------------------------------------------------------
# Check container existence
# ------------------------------------------------------------

container_exists() {
    proot-distro list --quiet 2>/dev/null |
        grep -Fxq "$PWSH_CONTAINER"
}

# ------------------------------------------------------------
# Architecture check
# ------------------------------------------------------------

check_architecture() {
    info "Checking architecture..."

    local ARCH
    ARCH="$(uname -m)"

    if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
        error "This installer expects ARM64/aarch64."
        error "Detected architecture: $ARCH"
        exit 1
    fi

    success "Architecture: $ARCH"
}

# ------------------------------------------------------------
# Termux dependencies
# ------------------------------------------------------------

check_termux() {
    info "Checking Termux dependencies..."

    if [[ "$SKIP_UPDATE" == "true" ]]; then
        warn "Skipping Termux repository refresh."

        # Use apt directly instead of pkg.
        # pkg may trigger repository/mirror refresh behavior.
        apt install -y \
            proot-distro \
            curl \
            tar \
            gzip
    else
        apt update

        apt install -y \
            proot-distro \
            curl \
            tar \
            gzip
    fi

    success "Termux dependencies ready."
}

# ------------------------------------------------------------
# Install pwsh Debian container
# ------------------------------------------------------------

install_container() {
    if container_exists; then
        info "Container '$PWSH_CONTAINER' already exists."
        return 0
    fi

    info "Creating dedicated Debian container: $PWSH_CONTAINER"

    if proot-distro install --help 2>&1 | grep -q -- '--name'; then

        proot-distro install \
            --name "$PWSH_CONTAINER" \
            debian

    else

        proot-distro install \
            --override-alias "$PWSH_CONTAINER" \
            debian

    fi

    success "Container '$PWSH_CONTAINER' created."
}

# ------------------------------------------------------------
# Debian dependencies
# ------------------------------------------------------------

install_dependencies() {
    info "Installing Debian dependencies..."

    proot-distro login "$PWSH_CONTAINER" -- /bin/bash -c '
        set -e

        NEED_UPDATE="false"

        # Fresh proot containers may not have package indexes.
        if ! find /var/lib/apt/lists \
            -type f \
            \( -name "*Packages*" -o -name "*Sources*" \) \
            -print -quit 2>/dev/null |
            grep -q .; then

            NEED_UPDATE="true"
        fi

        if [[ "$NEED_UPDATE" == "true" ]]; then

            if [[ "'"$SKIP_UPDATE"'" == "true" ]]; then
                echo "[!] --skip-update requested, but Debian package lists are missing."
                echo "[!] Running apt-get update once because this is a fresh container."
            else
                echo "[+] Updating Debian package lists..."
            fi

            apt-get update

        elif [[ "'"$SKIP_UPDATE"'" == "true" ]]; then

            echo "[!] Skipping Debian apt-get update."

        else

            echo "[+] Updating Debian package lists..."
            apt-get update

        fi

        apt-get install -y \
            ca-certificates \
            curl \
            tar \
            gzip \
            tzdata \
            libgcc-s1 \
            libgssapi-krb5-2 \
            libicu76 \
            libssl3t64 \
            libstdc++6 \
            zlib1g
    '

    success "Debian dependencies installed."
}

# ------------------------------------------------------------
# Install PowerShell
# ------------------------------------------------------------

install_powershell() {
    info "Installing PowerShell $PWSH_VERSION..."

    proot-distro login "$PWSH_CONTAINER" -- /bin/bash -c "
        set -e

        mkdir -p '$PWSH_DIR'

        if [[ -x '$PWSH_DIR/pwsh' ]]; then
            echo '[+] PowerShell already installed.'
            exit 0
        fi

        cd /tmp

        echo '[+] Downloading PowerShell...'

        curl -L \
            --fail \
            --retry 3 \
            --retry-delay 2 \
            -o '$PWSH_ARCHIVE' \
            '$PWSH_URL'

        rm -rf '$PWSH_DIR'
        mkdir -p '$PWSH_DIR'

        echo '[+] Extracting PowerShell...'

        tar -xzf '$PWSH_ARCHIVE' \
            -C '$PWSH_DIR'

        chmod +x '$PWSH_DIR/pwsh'

        rm -f '$PWSH_ARCHIVE'
    "

    success "PowerShell installed."
}

# ------------------------------------------------------------
# Configure PowerShell profile
# ------------------------------------------------------------

configure_profile() {
    info "Configuring PowerShell PATH..."

    proot-distro login "$PWSH_CONTAINER" -- /bin/bash -c '
        set -e

        PROFILE="/root/.config/powershell/Microsoft.PowerShell_profile.ps1"

        mkdir -p "$(dirname "$PROFILE")"
        touch "$PROFILE"

        PATH_LINE='\''$env:PATH = "/root/powershell:/termux/bin:" + $env:PATH'\''

        if ! grep -Fxq "$PATH_LINE" "$PROFILE"; then
            echo "$PATH_LINE" >> "$PROFILE"
        fi
    '

    success "PowerShell PATH configured."
}

# ------------------------------------------------------------
# Create Termux pwsh wrapper
# ------------------------------------------------------------

create_wrapper() {
    info "Creating Termux command: pwsh"

    cat > "$WRAPPER" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash

exec proot-distro login pwsh \
    --bind "$PREFIX:/termux" \
    --bind "$HOME:/termux-home" \
    -- /root/powershell/pwsh "$@"
EOF

    chmod +x "$WRAPPER"

    success "Created: $WRAPPER"
}

# ------------------------------------------------------------
# Remove pwsh environment
# ------------------------------------------------------------

remove_installation() {
    if container_exists; then

        warn "Removing '$PWSH_CONTAINER'..."
        proot-distro remove "$PWSH_CONTAINER"

        success "Container '$PWSH_CONTAINER' removed."

    else

        info "Container '$PWSH_CONTAINER' is not installed."

    fi

    if [[ -f "$WRAPPER" ]]; then

        rm -f "$WRAPPER"

        success "Removed Termux wrapper: $WRAPPER"

    fi
}

# ------------------------------------------------------------
# Full installation
# ------------------------------------------------------------

install_all() {
    banner

    check_architecture
    check_termux
    install_container
    install_dependencies
    install_powershell
    configure_profile
    create_wrapper

    printf '\n'

    printf '%s%s╔══════════════════════════════════════════════════════╗%s\n' \
        "$GREEN" "$BOLD" "$RESET"

    printf '%s%s║        PowerShell installation complete!            ║%s\n' \
        "$GREEN" "$BOLD" "$RESET"

    printf '%s%s╚══════════════════════════════════════════════════════╝%s\n' \
        "$GREEN" "$BOLD" "$RESET"

    printf '\n'

    printf '%sStart:%s          pwsh\n' \
        "$CYAN" "$RESET"

    printf '%sVersion:%s        pwsh -Command '\''$PSVersionTable'\''\n' \
        "$CYAN" "$RESET"

    printf '%sNormal Debian:%s  proot-distro login debian\n' \
        "$CYAN" "$RESET"

    printf '%sTermux binaries:%s /termux/bin\n' \
        "$CYAN" "$RESET"

    printf '%sTermux home:%s     /termux-home\n' \
        "$CYAN" "$RESET"

    printf '\n'

    printf '%sMade By Aryan Giri | giriaryan694-a11y%s\n' \
        "$MAGENTA" "$RESET"
}

# ------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------

while [[ $# -gt 0 ]]; do

    case "$1" in

        --install)

            if [[ -n "$ACTION" ]]; then
                error "Multiple actions specified."
                exit 1
            fi

            ACTION="install"
            ;;

        --reinstall)

            if [[ -n "$ACTION" ]]; then
                error "Multiple actions specified."
                exit 1
            fi

            ACTION="reinstall"
            ;;

        --rm|--remove)

            if [[ -n "$ACTION" ]]; then
                error "Multiple actions specified."
                exit 1
            fi

            ACTION="remove"
            ;;

        --skip-update)

            SKIP_UPDATE="true"
            ;;

        --help|-h)

            show_help
            exit 0
            ;;

        *)

            error "Unknown option: $1"
            echo
            show_help
            exit 1
            ;;

    esac

    shift

done

# ------------------------------------------------------------
# No action
# ------------------------------------------------------------

if [[ -z "$ACTION" ]]; then
    show_help
    exit 0
fi

# ------------------------------------------------------------
# Actions
# ------------------------------------------------------------

case "$ACTION" in

    install)

        if container_exists; then

            banner

            warn "Container '$PWSH_CONTAINER' already exists."
            warn "Use --reinstall to recreate it."

            exit 0

        fi

        install_all
        ;;

    reinstall)

        banner

        if container_exists; then

            warn "This will DELETE the '$PWSH_CONTAINER' container."
            warn "All data stored inside it will be lost."
            echo

            read -r -p "Continue? [y/N] " CONFIRM

            if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
                echo "Cancelled."
                exit 0
            fi

            remove_installation
            echo

        fi

        install_all
        ;;

    remove)

        banner
        remove_installation
        ;;

esac
