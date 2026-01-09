#!/bin/bash

# ============================================================================
# STAGE 6: Validation & Verification
# ============================================================================
source "$(dirname "$0")/../lib/common.sh"

stage_start "06-validation"
check_not_root  # Run as user for checking user permissions!

# ----------------------------------------------------------------------------
# Step 1: Kernel & Boot
# ----------------------------------------------------------------------------
step 1 "Verify Kernel"

K_VER=$(uname -r)
info "Kernel: $K_VER"

if [[ "$K_VER" =~ ^6\.([0-9]+) ]]; then
    MIN=${BASH_REMATCH[1]}
    if [ "$MIN" -ge 15 ]; then
        success "Kernel version OK (6.15+)"
    else
        warn "Kernel version < 6.15. Performance may be suboptimal."
    fi
else
    warn "Unrecognized kernel version format."
fi

info "Checking cmdline for parameters..."
CMDLINE=$(cat /proc/cmdline)

if [[ "$CMDLINE" == *"modprobe.blacklist=ice"* ]]; then
    success "E610 Blacklist Active"
else
    error "E610 Blacklist NOT ACTIVE in cmdline!"
fi

if [[ "$CMDLINE" == *"iommu=pt"* ]]; then
    success "IOMMU Passthrough (pt) Mode Active"
else
    warn "iommu=pt NOT FOUND. Host performance may be suboptimal."
fi

if [[ "$CMDLINE" == *"amd_pstate=active"* ]]; then
    success "AMD P-State Active"
else
    warn "AMD P-State not found in cmdline."
fi

# ----------------------------------------------------------------------------
# Step 2: Graphics
# ----------------------------------------------------------------------------
step 2 "Verify Graphics Stack"

if command -v glxinfo &>/dev/null; then
    RENDERER=$(glxinfo | grep "OpenGL renderer")
    info "$RENDERER"
    if [[ "$RENDERER" == *"AMD"* ]]; then
        success "OpenGL using AMD GPU"
    else
        warn "OpenGL might not be using AMD GPU (Check: $RENDERER)"
    fi
else
    warn "glxinfo not found (install mesa-utils)"
fi

if command -v vulkaninfo &>/dev/null; then
    # vulkaninfo produces a lot of output, just check exit code or summary
    if vulkaninfo --summary &>/dev/null; then
        success "Vulkan stack functioning"
    else
        error "vulkaninfo failed!"
    fi
else
    warn "vulkaninfo not found (install vulkan-tools)"
fi

# ----------------------------------------------------------------------------
# Step 3: LXD
# ----------------------------------------------------------------------------
step 3 "Verify LXD Container System"

if systemctl is-active --quiet lxd; then
    success "LXD Service Active"
else
    error "LXD Service NOT Active"
fi

info "Checking user group access..."
if groups | grep -q "lxd"; then
    success "User is in 'lxd' group"
    
    # Try listing containers (requires group access)
    if lxc list &>/dev/null; then
        success "LXD permission check passed (socket accessible)"
        
        # --------------------------------------------------------------------
        # Test Container GPU Access
        # --------------------------------------------------------------------
        if confirm "Launch test container to verify GPU Passthrough?"; then
            run_cmd "Launching 'gpu-test'" lxc launch images:archlinux/current gpu-test
            
            # Wait for container to start
            spin "Waiting for container IP..." "while [ -z \"\$(lxc list gpu-test -c 4 --format csv)\" ]; do sleep 1; done"
            
            info "Checking devices inside container..."
            
            # Check for /dev/kfd (Compute)
            if lxc exec gpu-test -- ls -l /dev/kfd &>/dev/null; then
                success "Compute Device (/dev/kfd) PASSED"
            else
                error "Compute Device (/dev/kfd) NOT FOUND in container"
            fi
            
            # Check for /dev/dri/renderD128 (Graphics/Compute)
            if lxc exec gpu-test -- ls /dev/dri/renderD128 &>/dev/null; then
                success "Render Device (/dev/dri/renderD128) PASSED"
            else
                error "Render Device NOT FOUND in container"
            fi
            
            if confirm_yes "Delete test container?"; then
                run_cmd "Deleting gpu-test" lxc delete --force gpu-test
            fi
        fi
        
    else
        error "Cannot access LXD socket. Did you re-login after adding group?"
    fi
else
    error "User is NOT in 'lxd' group"
fi

# ----------------------------------------------------------------------------
# Step 4: Summary
# ----------------------------------------------------------------------------
step 4 "Overall System Status"

FAILED_CHECKS=$(grep "❌" "$STAGE_LOG" | wc -l)
if [ "$FAILED_CHECKS" -eq 0 ]; then
    success "All checks passed! System is ready for Strix Halo development."
else
    warn "$FAILED_CHECKS checks failed. Review log for details."
fi

stage_complete
pause
