#!/bin/bash

# ============================================================================
# STAGE 7: User Applications (Dev, Office, Internet)
# ============================================================================
source "$(dirname "$0")/../lib/common.sh"

stage_start "07-user-apps"
check_root

# ----------------------------------------------------------------------------
# Step 0: AUR Helper (Required for some apps)
# ----------------------------------------------------------------------------
step 0 "Setup AUR Helper"

if ! command -v yay &>/dev/null; then
    info "Installing 'yay' for AUR support..."
    run_cmd "Installing yay" pacman -S --needed --noconfirm yay
fi

# ----------------------------------------------------------------------------
# Step 1: Internet & Browsers
# ----------------------------------------------------------------------------
step 1 "Install Web Browsers"
info "Note: You can install multiple browsers independently."

if confirm_yes "Install Firefox?"; then
    run_cmd "Installing Firefox" pacman -S --needed --noconfirm firefox
fi

if confirm "Install Google Chrome?"; then
    run_cmd "Installing Chrome" yay -S --needed --noconfirm google-chrome
fi

if confirm "Install Ungoogled Chromium?"; then
    run_cmd "Installing Ungoogled Chromium" yay -S --needed --noconfirm ungoogled-chromium-bin
fi

if confirm "Install Helium Browser?"; then
    # Helium often carbon-based or minimal floating browser.
    # Assuming 'helium-browser' or 'helium'. 
    # If not found, manual build required.
    run_cmd "Installing Helium" yay -S --needed --noconfirm helium
fi

# ----------------------------------------------------------------------------
# Step 2: Development Tools
# ----------------------------------------------------------------------------
step 2 "Install Development Tools"

if confirm_yes "Install Antigravity (IDE)?"; then
    # Confirmed package name: antigravity-bin (AUR)
    # Using -bin version for stability and speed
    run_cmd "Installing Antigravity IDE" yay -S --needed --noconfirm antigravity-bin
else
    info "Skipping Antigravity."
fi

# ----------------------------------------------------------------------------
# Step 3: Office Suite
# ----------------------------------------------------------------------------
step 3 "Install Office Suite"

if confirm "Install OnlyOffice?"; then
    run_cmd "Installing OnlyOffice" yay -S --needed --noconfirm onlyoffice-bin
fi

# ----------------------------------------------------------------------------
# Step 4: Communication
# ----------------------------------------------------------------------------
step 4 "Install Communication Tools"

if confirm "Install Signal Desktop?"; then
    run_cmd "Installing Signal" pacman -S --needed --noconfirm signal-desktop
fi

# ----------------------------------------------------------------------------
# Step 5: Media
# ----------------------------------------------------------------------------
step 5 "Install Media Tools"

if confirm "Install VLC Media Player?"; then
    run_cmd "Installing VLC" pacman -S --needed --noconfirm vlc
fi

stage_complete
pause
