#!/bin/bash

# ============================================================================
# MASTER CONTROL: Strix Halo CachyOS Setup Wizard
# ============================================================================

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# UI FUNCTIONS
# ============================================================================

# Draw a centered menu title
draw_menu_header() {
    clear
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${MAGENTA}  🤖 STRIX HALO (GFX1150) CACHYOS SETUP WIZARD${NC}"
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Kernel: $(uname -r) | User: $USER"
    echo ""
}

# Draw a menu option
# Usage: draw_option "1" "Step Name" "Status"
draw_option() {
    local key="$1"
    local name="$2"
    local stage_id="$3"
    
    local status="PENDING"
    local color="${CYAN}"
    local icon="○"
    
    # Check status log if stage_id is provided
    if [ -n "$stage_id" ]; then
        local valid_status=$(get_stage_status "$stage_id")
        if [ "$valid_status" == "COMPLETED" ]; then
            status="DONE"
            color="${GREEN}"
            icon="●"
        elif [ "$valid_status" == "FAILED" ]; then
            status="FAILED"
            color="${RED}"
            icon="✖"
        elif [ "$valid_status" == "STARTED" ]; then
            status="IN PROGRESS"
            color="${YELLOW}"
            icon="◐"
        fi
    fi
    
    printf "  ${BOLD}%s) ${color}%s %-40s [ %s ]${NC}\n" "$key" "$icon" "$name" "$status"
}

# Run a stage script
run_stage() {
    local script="$1"
    local name="$2"
    
    clear
    echo -e "${BOLD}${MAGENTA}>>> STARTING: $name${NC}"
    echo ""
    
    if [ -f "${SCRIPT_DIR}/stages/$script" ]; then
        chmod +x "${SCRIPT_DIR}/stages/$script"
        sudo "${SCRIPT_DIR}/stages/$script"
        echo ""
        read -p "Press Enter to return to menu..."
    else
        echo -e "${RED}Error: Script $script not found!${NC}"
        read -p "Press Enter to continue..."
    fi
}

# ============================================================================
# MAIN LOOP
# ============================================================================

# Check root - we want to be run as normal user (script invokes sudo per stage)
check_not_root

while true; do
    draw_menu_header
    
    echo -e "${BOLD}  Installation Stages:${NC}"
    echo ""
    
    draw_option "1" "Kernel Configuration (E610 Fix)" "01-kernel-config"
    draw_option "2" "Graphics Stack (Mesa/Vulkan)"  "02-graphics-setup"
    draw_option "3" "System Update & Packages"      "03-system-update"
    draw_option "4" "LXD Container Setup"           "04-lxd-setup"
    draw_option "5" "Cleanup (Remove AI Sysadmin)"  "05-cleanup"
    draw_option "6" "User Applications (Dev/Office)" "07-user-apps"
    draw_option "7" "Workspace Provisioning (AI/Dev)" "08-workspace-setup"
    draw_option "8" "Validation & Testing"          "06-validation"
    
    echo ""
    echo -e "${BOLD}  Other Operations:${NC}"
    echo ""
    printf "  ${BOLD}v)${NC} View Version Requirements\n"
    printf "  ${BOLD}p)${NC} View Package Manifest\n"
    printf "  ${BOLD}l)${NC} View Logs\n"
    printf "  ${BOLD}q)${NC} Quit\n"
    
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -p "  Select an option: " selection
    
    case $selection in
        1) run_stage "01-kernel-config.sh" "Kernel Configuration" ;;
        2) run_stage "02-graphics-setup.sh" "Graphics Stack Setup" ;;
        3) run_stage "03-system-update.sh" "System Update" ;;
        4) run_stage "04-lxd-setup.sh" "LXD Setup" ;;
        5) run_stage "05-cleanup.sh" "Cleanup" ;;
        6) run_stage "07-user-apps.sh" "User Applications" ;;
        7) run_stage "08-workspace-setup.sh" "Workspace Provisioning" ;;
        8) run_stage "06-validation.sh" "Validation" ;;
        v|V)
            clear
            if command -v glow &>/dev/null; then
                glow "${SCRIPT_DIR}/docs/VERSION_REQUIREMENTS.md"
            else
                cat "${SCRIPT_DIR}/docs/VERSION_REQUIREMENTS.md" | less
            fi
            ;;
        p|P)
            clear
            if command -v glow &>/dev/null; then
                glow "${SCRIPT_DIR}/docs/PACKAGES.md"
            else
                cat "${SCRIPT_DIR}/docs/PACKAGES.md" | less
            fi
            ;;
        l|L)
            clear
            echo "Logs available in ${SCRIPT_DIR}/logs/:"
            ls -lt "${SCRIPT_DIR}/logs/"
            echo ""
            read -p "Press Enter to return..."
            ;;
        q|Q)
            clear
            echo "Exiting setup wizard. Good luck!"
            exit 0
            ;;
        *)
            ;;
    esac
done
