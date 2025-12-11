#!/bin/bash

# ============================================================================
# STAGE 3: System Update & Package Installation
# ============================================================================
source "$(dirname "$0")/../lib/common.sh"

stage_start "03-system-update"
check_root

# ----------------------------------------------------------------------------
# Step 1: Update Mirrors (CachyOS)
# ----------------------------------------------------------------------------
step 1 "Optimize Mirrors"

if confirm_yes "Rank mirrors for speed?"; then
    # CachyOS usually has 'cachyos-rate-mirrors' or similar, but generic Arch way:
    if command -v cachyos-rate-mirrors &>/dev/null; then
        run_cmd "Ranking CachyOS mirrors" cachyos-rate-mirrors
    elif command -v rate-mirrors &>/dev/null; then
        warn "Using generic rate-mirrors"
        run_cmd "Ranking mirrors" "rate-mirrors arch | tee /etc/pacman.d/mirrorlist"
    else
        warn "No mirror ranking tool found, skipping."
    fi
fi

# ----------------------------------------------------------------------------
# Step 2: Full System Update
# ----------------------------------------------------------------------------
step 2 "Full System Update"

log "Running pacman -Syu"
if confirm_yes "Perform full system update?"; then
    run_cmd "Updating system" pacman -Syu --noconfirm
fi

# ----------------------------------------------------------------------------
# Step 3: Install Essential Build Tools
# ----------------------------------------------------------------------------
step 3 "Install Essentials"

ESSENTIALS="base-devel git wget curl vim neovim btop neofetch fastfetch"
info "Packages: $ESSENTIALS"

if confirm_yes "Install essential tools?"; then
    run_cmd "Installing essentials" pacman -S --needed --noconfirm $ESSENTIALS
fi

# ----------------------------------------------------------------------------
# Step 4: CachyOS Testing Repo (Optional)
# ----------------------------------------------------------------------------
step 4 "Testing Repository Config (Optional)"

info "Requires testing repo for latest Mesa?"
info "Only enable if your Mesa version is < 24.1 (checked in Stage 2)"

if confirm "Enable CachyOS testing repositories?"; then
    # Usually uncomment lines in /etc/pacman.conf
    if grep -q "#\[cachyos-testing\]" /etc/pacman.conf; then
        run_cmd "Enabling cachyos-testing" \
            "sed -i 's/#\[cachyos-testing\]/\[cachyos-testing\]/' /etc/pacman.conf"
        
        # Usually need to uncomment the Include line below it too
        # This is a bit risky with sed without seeing the file structure.
        # Safer: append if not present, or warn user to do it manually.
        warn "Attempted to uncomment [cachyos-testing]. Please verify /etc/pacman.conf manually."
        run_cmd "Syncing after repo change" pacman -Sy
    else
        warn "cachyos-testing not found commented out in pacman.conf."
        info "You may need to add it manually:"
        echo "[cachyos-testing]"
        echo "Include = /etc/pacman.d/cachyos-testing.mirrorlist"
    fi
fi

stage_complete
pause
