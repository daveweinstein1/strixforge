#!/bin/bash

# ============================================================================
# COMMON LIBRARY: Shared functions for all stage scripts
# ============================================================================
# Source this file in all stage scripts:
#   source "$(dirname "$0")/../lib/common.sh"
# ============================================================================

# Prevent double-sourcing
if [ -n "$_COMMON_SH_LOADED" ]; then
    return 0
fi
_COMMON_SH_LOADED=1

# ============================================================================
# CONFIGURATION
# ============================================================================

# Find the script root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
DOCS_DIR="${SCRIPT_DIR}/docs"

# Create log directory
mkdir -p "$LOG_DIR"

# Current stage (set by each stage script)
CURRENT_STAGE="${CURRENT_STAGE:-unknown}"

# Log file paths
MAIN_LOG="${LOG_DIR}/install.log"
STAGE_LOG="${LOG_DIR}/${CURRENT_STAGE}.log"
ERROR_LOG="${LOG_DIR}/${CURRENT_STAGE}.error.log"
AI_CONTEXT_LOG="${LOG_DIR}/${CURRENT_STAGE}.ai-context.log"

# ============================================================================
# COLORS
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

# Get timestamp
timestamp() {
    date +'%Y-%m-%d %H:%M:%S'
}

# Log to both terminal and file
log() {
    local msg="[$(timestamp)] $*"
    echo -e "${BLUE}${msg}${NC}"
    echo "$msg" >> "$MAIN_LOG"
    echo "$msg" >> "$STAGE_LOG"
}

# Success message
success() {
    local msg="[$(timestamp)] ✅ $*"
    echo -e "${GREEN}${msg}${NC}"
    echo "$msg" >> "$MAIN_LOG"
    echo "$msg" >> "$STAGE_LOG"
}

# Warning message
warn() {
    local msg="[$(timestamp)] ⚠️  $*"
    echo -e "${YELLOW}${msg}${NC}"
    echo "$msg" >> "$MAIN_LOG"
    echo "$msg" >> "$STAGE_LOG"
}

# Error message
error() {
    local msg="[$(timestamp)] ❌ $*"
    echo -e "${RED}${msg}${NC}"
    echo "$msg" >> "$MAIN_LOG"
    echo "$msg" >> "$STAGE_LOG"
    echo "$msg" >> "$ERROR_LOG"
}

# Info message (cyan)
info() {
    local msg="[$(timestamp)] ℹ️  $*"
    echo -e "${CYAN}${msg}${NC}"
    echo "$msg" >> "$MAIN_LOG"
    echo "$msg" >> "$STAGE_LOG"
}

# Header for sections
header() {
    local msg="$*"
    local line="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${BOLD}${MAGENTA}${line}${NC}"
    echo -e "${BOLD}${MAGENTA}  $msg${NC}"
    echo -e "${BOLD}${MAGENTA}${line}${NC}"
    echo ""
    echo "=== $msg ===" >> "$STAGE_LOG"
}

# ============================================================================
# CONFIRMATION FUNCTIONS
# ============================================================================

# Ask for confirmation
confirm() {
    local prompt="${1:-Continue?}"
    echo -e "${YELLOW}⏸️  ${prompt}${NC}"
    read -p "[y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Ask for confirmation with default yes
confirm_yes() {
    local prompt="${1:-Continue?}"
    echo -e "${YELLOW}⏸️  ${prompt}${NC}"
    read -p "[Y/n] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Nn]$ ]]
}

# Wait for user to press enter
pause() {
    local msg="${1:-Press Enter to continue...}"
    echo -e "${CYAN}${msg}${NC}"
    read -r
}

# ============================================================================
# COMMAND EXECUTION WITH LOGGING
# ============================================================================

# Run a command with full logging and error handling
# Usage: run_cmd "description" command args...
run_cmd() {
    local description="$1"
    shift
    local cmd="$*"
    
    log "Running: $description"
    echo -e "${CYAN}Command:${NC} $cmd"
    
    # Run and stream to stdout AND log
    # We use PIPESTATUS to capture the exit code of the evaluated command
    set +e
    eval "$cmd" 2>&1 | tee -a "$STAGE_LOG"
    local exit_code=${PIPESTATUS[0]}
    set -e
    
    # Handle result
    if [ $exit_code -eq 0 ]; then
        success "$description"
        return 0
    else
        error "$description FAILED (exit code: $exit_code)"
        
        # Generate AI context log from the stage log (last 50 lines)
        generate_ai_context "$description" "$cmd" "$exit_code" "$STAGE_LOG"
        
        return $exit_code
    fi
}

# Run command with confirmation first
# Usage: run_cmd_confirm "description" command args...
run_cmd_confirm() {
    local description="$1"
    shift
    local cmd="$*"
    
    echo ""
    echo -e "${BOLD}About to run:${NC} $description"
    echo -e "${CYAN}Command:${NC} $cmd"
    echo ""
    
    if confirm "Execute this command?"; then
        run_cmd "$description" "$cmd"
        return $?
    else
        warn "Skipped: $description"
        return 0
    fi
}

# ============================================================================
# AI CONTEXT GENERATION
# ============================================================================

# Generate a log specifically formatted for AI diagnosis
generate_ai_context() {
    local description="$1"
    local cmd="$2"
    local exit_code="$3"
    local output_file="$4"
    
    cat > "$AI_CONTEXT_LOG" << EOF
================================================================================
STRIX HALO INSTALLATION ERROR - AI DIAGNOSTIC CONTEXT
================================================================================

Generated: $(timestamp)
Stage: ${CURRENT_STAGE}
Description: ${description}

================================================================================
FAILED COMMAND
================================================================================

Command: ${cmd}
Exit Code: ${exit_code}

================================================================================
COMMAND OUTPUT (Last 50 lines)
================================================================================

$(tail -n 50 "$output_file" 2>/dev/null || echo "No output captured")

================================================================================
SYSTEM INFORMATION
================================================================================

Kernel: $(uname -r)
Architecture: $(uname -m)
Distribution: $(cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" | cut -d= -f2 | tr -d '"')

================================================================================
RELEVANT PACKAGE VERSIONS
================================================================================

$(pacman -Q mesa linux linux-firmware llvm 2>/dev/null || echo "Unable to query packages")

================================================================================
GPU INFORMATION
================================================================================

$(lspci | grep -i vga 2>/dev/null || echo "Unable to query GPU")
$(lspci | grep -i amd 2>/dev/null || echo "")

================================================================================
RECENT LOG CONTEXT (Last 30 lines before error)
================================================================================

$(tail -n 30 "$STAGE_LOG" 2>/dev/null || echo "No log context available")

================================================================================
INSTRUCTIONS FOR AI
================================================================================

This error occurred during CachyOS installation for AMD Strix Halo (gfx1150).
Please analyze the error and suggest:
1. What went wrong
2. How to fix it
3. Any alternative approaches

Target versions:
- Kernel: 6.18+ (Bleeding Edge Strix Halo)
- Mesa: 25.3.1+ (Strix Support)
- LLVM: 21.x (Shader Compiler)
- ROCm: 7.1+ (Critical for Compute)

================================================================================
EOF

    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ERROR: Command failed!${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}🤖 AI Diagnostic Context saved to:${NC}"
    echo "   $AI_CONTEXT_LOG"
    echo ""
    echo -e "${YELLOW}To get help, copy the contents of that file and paste to an AI.${NC}"
    echo ""
    echo -e "${CYAN}Quick copy command:${NC}"
    echo "   cat '$AI_CONTEXT_LOG' | xclip -selection clipboard"
    echo ""
}

# ============================================================================
# ROOT CHECK
# ============================================================================

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root"
        echo "Run: sudo $0"
        exit 1
    fi
}

check_not_root() {
    if [ "$EUID" -eq 0 ]; then
        error "This script should NOT be run as root"
        echo "Run without sudo: $0"
        exit 1
    fi
}

# ============================================================================
# SYSTEM CHECKS
# ============================================================================

# Check if running on Arch/CachyOS
check_arch() {
    if ! command -v pacman &> /dev/null; then
        error "This script requires pacman (Arch/CachyOS)"
        exit 1
    fi
}

# Check internet connectivity
check_internet() {
    log "Checking internet connectivity..."
    if ping -c 1 archlinux.org &> /dev/null; then
        success "Internet connection OK"
        return 0
    else
        error "No internet connection"
        return 1
    fi
}

# Check if a package is installed
is_installed() {
    pacman -Q "$1" &> /dev/null
}

# Get package version
get_version() {
    pacman -Q "$1" 2>/dev/null | awk '{print $2}'
}

# ============================================================================
# STAGE MANAGEMENT
# ============================================================================

# Mark stage as started
stage_start() {
    local stage_name="$1"
    CURRENT_STAGE="$stage_name"
    STAGE_LOG="${LOG_DIR}/${CURRENT_STAGE}.log"
    ERROR_LOG="${LOG_DIR}/${CURRENT_STAGE}.error.log"
    AI_CONTEXT_LOG="${LOG_DIR}/${CURRENT_STAGE}.ai-context.log"
    
    header "STAGE: $stage_name"
    log "Stage started"
    echo "$stage_name:STARTED:$(timestamp)" >> "${LOG_DIR}/stage-status.log"
}

# Mark stage as completed
stage_complete() {
    success "Stage $CURRENT_STAGE completed successfully"
    echo "$CURRENT_STAGE:COMPLETED:$(timestamp)" >> "${LOG_DIR}/stage-status.log"
}

# Mark stage as failed
stage_failed() {
    error "Stage $CURRENT_STAGE FAILED"
    echo "$CURRENT_STAGE:FAILED:$(timestamp)" >> "${LOG_DIR}/stage-status.log"
}

# Check stage status
get_stage_status() {
    local stage="$1"
    grep "^$stage:" "${LOG_DIR}/stage-status.log" 2>/dev/null | tail -1 | cut -d: -f2
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Print a divider line
divider() {
    echo "────────────────────────────────────────────────────────────"
}

# Print step header
step() {
    local num="$1"
    local desc="$2"
    
    # Resume Logic: Skip if RESUME_STEP is set and higher than current step
    if [ -n "$RESUME_STEP" ] && [ "$num" -lt "$RESUME_STEP" ]; then
        echo -e "${YELLOW}⏩ Skipping Step $num (Resuming from $RESUME_STEP)...${NC}"
        return
    fi

    echo ""
    log "Step $num: $desc"
    divider
}

# Show spinner while command runs
# Usage: spin "message" command args...
spin() {
    local msg="$1"
    shift
    local cmd="$*"
    
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    eval "$cmd" &>> "$STAGE_LOG" &
    local pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r${spin:$i:1} %s" "$msg"
        sleep 0.1
    done
    
    wait $pid
    local result=$?
    
    if [ $result -eq 0 ]; then
        printf "\r✅ %s\n" "$msg"
    else
        printf "\r❌ %s\n" "$msg"
    fi
    
    return $result
}
