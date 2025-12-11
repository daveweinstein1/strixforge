#!/bin/bash

# ============================================================================
# STAGE 5: Cleanup & Optimization
# ============================================================================
source "$(dirname "$0")/../lib/common.sh"

stage_start "05-cleanup"
check_root

# ----------------------------------------------------------------------------
# Step 1: Remove "AI Sysadmin" Stuff
# ----------------------------------------------------------------------------
step 1 "Remove AI/Experimental Software"

info "Checking for commonly installed AI tools that might need cleanup..."

# List of potential packages to remove if user wants a "clean slate"
# This assumes 'AI sysadmin stuff' refers to specific tools
POTENTIAL_REMOVALS="ollama llama.cpp python-pytorch-rocm python-tensorflow-rocm cockpit webmin"

FOUND_PACKAGES=""
for pkg in $POTENTIAL_REMOVALS; do
    if pacman -Q "$pkg" &>/dev/null; then
        FOUND_PACKAGES="$FOUND_PACKAGES $pkg"
    fi
done

if [ -n "$FOUND_PACKAGES" ]; then
    warn "Found potential AI/Sysadmin packages: $FOUND_PACKAGES"
    if confirm "Remove these packages?"; then
        run_cmd "Removing packages" pacman -Rns --noconfirm $FOUND_PACKAGES
    fi
else
    success "No common AI/Sysadmin packages found."
fi

# ----------------------------------------------------------------------------
# Step 2: Orphan Cleanup
# ----------------------------------------------------------------------------
step 2 "Remove Orphaned Packages"

# Check for orphans
if [ -n "$(pacman -Qtdq)" ]; then
    ORPHANS=$(pacman -Qtdq)
    info "Found orphaned packages (dependencies no longer needed):"
    echo "$ORPHANS"
    
    if confirm_yes "Remove orphans?"; then
        run_cmd "Removing orphans" "pacman -Rns --noconfirm $ORPHANS"
    fi
else
    success "No orphans found."
fi

# ----------------------------------------------------------------------------
# Step 3: Cache Cleanup
# ----------------------------------------------------------------------------
step 3 "Clean Pacman Cache"

info "Frees disk space by removing old package versions."
if confirm_yes "Clean package cache?"; then
    run_cmd "Cleaning cache" "echo y | pacman -Scc"
fi

stage_complete
pause
