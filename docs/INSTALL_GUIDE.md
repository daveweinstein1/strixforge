# CachyOS Installation Guide for Strix Halo
**Version**: 2025.12.11  |  **Date**: December 11, 2025  |  **Author**: Dave Weinstein (@daveweinstein1)

## Why CachyOS?
For cutting-edge hardware like the Strix Halo (launched early 2025), CachyOS offers distinct advantages over traditional fixed-release distributions like Ubuntu or Kubuntu.

### 1. Optimized for Strix Halo
*   **Proven Performance**: CachyOS demonstrated strong performance leads with Strix Halo in recent Phoronix benchmarks.
    *   Review: https://www.phoronix.com/review/amd-strix-halo-linux-7
*   **Automatic Optimization**: The CachyOS installer automatically detects Strix Halo's **Znver5** architecture and installs a specifically optimized kernel (`linux-cachyos-znver5`). This tailored compilation can deliver a **~10% performance increase** compared to generic Linux kernels.
*   **Zen 5 Architecture**: The entire package distribution is compiled to extract maximum throughput from the 16-core processor and NPU.

### 2. Superior for AI Development
*   **Bleeding Edge Access**: Being Arch-based (rolling release) means you get the newest PyTorch, TensorFlow, and ROCm drivers immediately. This is critical for new APUs where driver support evolves weekly.
*   **AUR Advantage**: You gain access to the Arch User Repository (AUR) for the latest AI/ML tools.
*   **Performance Edge**: While Ubuntu 25.10 runs AI models on Strix Halo adequately, CachyOS's scheduler and kernel optimizations provide a tangible edge in compute tasks.

### 3. Windows-like Experience
*   CachyOS defaults to KDE Plasma, providing a familiar, highly customizable interface similar to Windows, which minimizes the learning curve for new switchers.

## Version Requirements (Critical)

| Component | Version | Notes |
|-----------|---------|-------|
| Kernel | **6.18+** | Bleeding Edge (Active Strix Halo Work) |
| ROCm | **7.1+** | Critical for Compute/AI |
| Mesa | **25.3.1+** | Required for GFX1150 |

> [!IMPORTANT]
> Ensure you are using CachyOS `v3/v4` repositories to meet these requirements.

## Device Specific Notes

### Beelink GTR9 Pro
1.  **Disable E610 Ethernet**: The internal 10Gb Ethernet causes crashes.
    *   **BIOS**: Go to `Advanced` -> `Demo Board` -> `PCI-E Port` -> `Device 3 Fun 2` -> **Disabled**.
    *   **Kernel**: Stage 1 script will also blacklist the `ice` driver (`modprobe.blacklist=ice`) as a safeguard.
2.  **TDP Control**: Stage 1 includes an interactive tool to limit power to **55W** (Silent) or **80W** (Balanced) using `ryzenadj`.

### Framework Desktop
*   **Golden Path**: Framework hardware is fully compatible out of the box. No E610 workarounds are required. Use standard settings.

## Part 1: Manual Installation (Before Scripts)

This is the step-by-step guide you must follow BEFORE any scripts can run. 
Scripts only work AFTER CachyOS is installed and bootable.

---

## Phase A: Prepare Installation Media with Ventoy

### A.1: Download Ventoy

**On your current Windows/Linux system:**

1. Go to: https://www.ventoy.net/en/download.html
2. Download the latest Ventoy release for your OS:
   - Windows: `ventoy-x.x.xx-windows.zip`
   - Linux: `ventoy-x.x.xx-linux.tar.gz`

### A.2: Install Ventoy to USB Drive

**Requirements:**
- USB drive: 16GB+ recommended (32GB+ ideal for multiple ISOs)
- WARNING: This will ERASE the USB drive completely

**Windows:**
```
1. Extract ventoy-x.x.xx-windows.zip
2. Run Ventoy2Disk.exe
3. Select your USB drive from the dropdown
4. Click "Install"
5. Confirm the warning about data loss
6. Wait for "Ventoy installation successful" message
```

**Linux:**
```bash
# Extract
tar -xzf ventoy-x.x.xx-linux.tar.gz
cd ventoy-x.x.xx

# Find your USB device (careful - don't pick wrong disk!)
lsblk

# Install (replace sdX with your USB device)
sudo ./Ventoy2Disk.sh -i /dev/sdX
```

### A.3: Download CachyOS ISO

1. Go to: https://cachyos.org/download/
2. Download: **CachyOS Desktop** (latest release)
   - Recommended: KDE or GNOME edition
   - Filename: `cachyos-desktop-linux-xxxx.iso`

### A.4: Copy Files to Ventoy USB

After Ventoy is installed, your USB will show as a regular drive.

1. Copy the CachyOS ISO to the root of the Ventoy partition
2. Create a folder called `strix-halo-setup` 
3. Copy ALL the installation scripts to this folder:
   ```
   Ventoy USB/
   ├── cachyos-desktop-linux-xxxx.iso
   └── strix-halo-setup/
       ├── master-control.sh
       ├── lib/
       │   └── common.sh
       ├── stages/
       │   ├── 01-kernel-config.sh
       │   ├── 02-graphics-setup.sh
       │   ├── 03-system-update.sh
       │   ├── 04-lxd-setup.sh
       │   ├── 05-cleanup.sh
       │   ├── 06-validation.sh
       │   ├── 07-user-apps.sh
       │   └── 08-workspace-setup.sh
       └── docs/
           ├── INSTALL_GUIDE.md
           └── VERSION_REQUIREMENTS.md
   ```

### A.5: Verify Ventoy USB

1. Safely eject the USB
2. Reinsert it
3. Verify you can see:
   - At least one ISO file
   - The `strix-halo-setup` folder with scripts

---

## Phase B: BIOS/UEFI Configuration

**Before booting from USB, configure BIOS:**

### B.1: Enter BIOS Setup

1. Restart the Strix Halo system
2. Press the BIOS key during boot (usually `DEL`, `F2`, or `F10`)
3. Navigate to BIOS setup

### B.2: Required BIOS Settings

Check/set each of these:

| Setting | Required Value | Location (varies by board) |
|---------|---------------|---------------------------|
| Secure Boot | **DISABLED** | Security → Secure Boot |
| Boot Mode | **UEFI** (not Legacy/CSM) | Boot → Boot Mode |
| IOMMU | **ENABLED** | Advanced → AMD CBS → NBIO |
| SVM Mode | **ENABLED** | Advanced → CPU Configuration |
| Fast Boot | **DISABLED** | Boot → Fast Boot |
| **10GbE LAN (E610)** | **DISABLED** | Internal Devices (See Device Specifics) |

### B.3: Device-Specific BIOS Paths

#### **Beelink GTR9 Pro (BIOS v1.08)**
*Use distinct settings for stability (E610) and performance.*

| Setting | Desired Value | Default? | Exact Menu Path (v1.08) |
|---------|---------------|----------|-------------------------|
| **Device 3 Fun 2** | **Disabled** | Enabled | `Advanced` → `Demo Board` → `PCI-E Port` → `Device 3 Fun 2` |
| Secure Boot | Disabled | Enabled | `Security` → `Secure Boot` |
| IOMMU | Enabled | Auto | `Advanced` → `AMD CBS` → `NBIO Common Options` |
| SVM Mode | Enabled | Enabled | `Advanced` → `CPU Config` → `SVM Mode` |

> [!NOTE]
> **Why "Device 3 Fun 2"?** This esoteric setting is the specific PCIe function for the E610 10GbE controller. Disabling it here affects the hardware restart loop issue more effectively than the OS-level blacklist.

#### **Framework Desktop**
*Most virtualization features are enabled by factory default. Focus on Secure Boot.*

| Setting | Desired Value | Default? | Exact Menu Path |
|---------|---------------|----------|-----------------|
| Secure Boot | **Disabled** | Enabled | `Security` → `Secure Boot` → `Enforce Secure Boot` |
| IOMMU / SVM | **Enabled** | **Yes** | *(Hidden / Always Enabled on Firmware level)* |
| VRAM | Auto | Auto | `Advanced` → `IGPU Config` → `UMA Frame Buffer Size` |

> [!TIP]
> **VRAM Note**: Strix Halo uses Unified Memory. Leaving VRAM on "Auto" is recommended. The OS will dynamically allocate up to 96GB+ for AI/GPU workloads as needed.

### B.4: Set Boot Priority

1. Navigate to Boot menu
2. Set USB drive as first boot device
3. Save changes and exit (usually F10)

---

## Phase C: Boot from Ventoy

### C.1: Insert USB and Boot

1. Insert the Ventoy USB
2. Power on (or restart) the system
3. You should see the Ventoy boot menu

### C.2: Select CachyOS ISO

1. Use arrow keys to select `cachyos-desktop-linux-xxxx.iso`
2. Press Enter
3. Select "Boot in normal mode" (first option)
4. Wait for CachyOS live environment to load

### C.3: Verify Live Environment

Once booted, you should see:
- CachyOS desktop (KDE/GNOME depending on ISO)
- Working display (if not, gfx1150 may have issues - try adding `nomodeset` to boot)

**If display doesn't work:**
1. Reboot
2. At Ventoy, select CachyOS ISO
3. Press `e` to edit boot options
4. Add `nomodeset` to the kernel command line
5. Press F10 to boot
6. This gives basic display - installer will set up proper drivers

---

## Phase D: CachyOS Installation

### D.1: Launch Installer

1. On the CachyOS desktop, find "Install CachyOS" icon
2. Double-click to launch Calamares installer

### D.2: Language & Locale

1. Select your language (English recommended for troubleshooting)
2. Select your region/timezone
3. Click Next

### D.3: Keyboard Layout

1. Select your keyboard layout
2. Test in the text box
3. Click Next

### D.4: Partitioning (CRITICAL)

**Option A: Erase Entire Disk (Recommended for dedicated system)**
1. Select "Erase disk"
2. Ensure BTRFS is selected as filesystem (for snapshots)
3. Ensure swap is created (with hibernate if desired)

**Option B: Manual Partitioning (Dual boot)**
Create these partitions:
| Mount Point | Size | Type | Filesystem |
|------------|------|------|------------|
| /boot/efi | 512 MB | EFI System | FAT32 |
| / | 100+ GB | Linux | BTRFS |
| swap | RAM size | Linux swap | swap |
| /home | Remaining | Linux | BTRFS (optional separate) |

4. Click Next

### D.5: Users

1. Enter your name
2. Create a username (lowercase, no spaces)
3. Set hostname (e.g., `strix-halo-workstation`)
4. Create a strong password
5. Select "Use same password for administrator"
6. Click Next

### D.6: Desktop Environment (if prompted)

1. Select your preferred desktop:
   - **KDE Plasma** - Feature-rich, customizable
   - **GNOME** - Clean, modern
   - **XFCE** - Lightweight
2. Click Next

### D.7: Review & Install

1. Review the summary
2. **Verify partitioning is correct** - this cannot be undone!
3. Click "Install"
4. Confirm the warning
5. Wait for installation to complete (15-30 minutes)

### D.8: Installation Complete

1. When prompted, select "Restart now"
2. Click "Done"
3. Remove the USB when prompted (or set BIOS to boot from disk first)
4. System will restart

---

## Phase E: First Boot & Script Preparation

### E.1: Login to New System

1. At login screen, enter your password
2. Wait for desktop to load
3. Open a terminal (Konsole for KDE, Terminal for GNOME)

### E.2: Verify Basic Functionality

```bash
# Check kernel version
uname -r

# Check if we have graphics (should show gfx1150 or similar)
lspci | grep -i vga

# Check internet
ping -c 3 archlinux.org
```

### E.3: Mount Ventoy USB and Copy Scripts

1. Insert the Ventoy USB
2. It should auto-mount. Find the mount point:
```bash
# Find where Ventoy USB is mounted
lsblk
# Look for a partition around 16-32GB, note the mount point
# Usually something like /run/media/username/Ventoy

# Copy scripts to home directory
cp -r /run/media/$USER/Ventoy/strix-halo-setup ~/
cd ~/strix-halo-setup

# Make scripts executable
chmod +x master-control.sh
chmod +x stages/*.sh
```

### E.4: Run Master Control Script

```bash
sudo ./master-control.sh
```

This launches the interactive setup wizard. Follow the on-screen prompts.

---

## Phase F: Post-Install Stages (Via Scripts)

Once the master control script is running, you'll proceed through:

| Stage | Purpose | Approx Time |
|-------|---------|-------------|
| 1 | Kernel Config (E610 Fix / IOMMU PT) | 5 min |
| 2 | Graphics Stack (Mesa/Vulkan) | 10 min |
| 3 | System Update | 15 min |
| 4 | LXD Container Setup (Auto GPU) | 10 min |
| 5 | Cleanup (remove AI sysadmin) | 5 min |
| 6 | User Applications (Dev/Office) | 5 min |
| 7 | Validation & Testing | 10 min |

Each stage:
- Shows what it will do before running
- Asks for confirmation before critical commands
- Logs everything to `~/strix-halo-setup/logs/`
- Provides AI-pasteable error context if something fails

---

## Quick Reference: Important Paths

| Item | Path |
|------|------|
| Script location | `~/strix-halo-setup/` |
| Logs | `~/strix-halo-setup/logs/` |
| Master control | `~/strix-halo-setup/master-control.sh` |
| Version docs | `~/strix-halo-setup/docs/VERSION_REQUIREMENTS.md` |

---

## Appendix A: Software Package Manifest
*(Source: `docs/PACKAGES.md`)*

### 1. Host OS (Hypervisor Layer)
The Host OS is kept minimal. Its only job is to provide hardware drivers (Kernel/Mesa) and manage containers.

#### Graphics Stack (Stage 2)
*Required for Strix Halo (gfx1150) hardware acceleration.*

| Package | Version Requirement | Purpose |
|---------|---------------------|---------|
| `mesa` | **25.3.1+** (Current) / 24.1+ (Min) | OpenGL/Vulkan User-space drivers |
| `vulkan-radeon` | Latest | RADV Vulkan driver (Critical for Gaming/Compute) |
| `llvm` | **21.x** (Current) / 17+ (Min) | Shader compiler backend for RADV |
| `linux-firmware` | Latest | GPU hardware firmware blobs |
| `mesa-utils` | - | Diagnostics (`glxinfo`) |
| `vulkan-tools` | - | Diagnostics (`vulkaninfo`) |

#### Virtualization & Containerization (Stage 4)
*Required for running AI workspaces.*

| Package | Purpose |
|---------|---------|
| `lxd` | System container manager (Daemon) |
| `lxc` | Command line client |
| `dnsmasq` | DHCP/DNS for container networking |
| `bridge-utils` | Network bridge creation |
| `iptables` / `ebtables` | Firewall/NAT rules for containers |

#### System Utilities (Stage 3)
*Build tools and basics.*

- `base-devel` (GCC, Make, etc - needed for compiling AUR helpers if required)
- `git`, `wget`, `curl`
- `vim`, `neovim`
- `btop` (System monitoring)
- `fastfetch` (System info)

### 2. Containers (AI Workspaces)
**NOTE:** The install scripts *prepare* the host for these, but do not pre-install them to keep the base image clean. You install these *inside* your LXD containers.

#### Recommended "Bleeding Edge" AI Stack
For Strix Halo AI Development:

| Component | Arch Package | Purpose |
|-----------|--------------|---------|
| **ROCm SDK** | `rocm-hip-sdk` | ROCm/HIP Development Platform |
| **PyTorch** | `python-pytorch-rocm` | PyTorch with ROCm backend support |
| **TensorFlow** | `python-tensorflow-rocm` | TensorFlow with ROCm backend |
| **ML Libraries** | `python-numpy`, `python-pandas` | Data Science Basics |

### 3. User Applications (Stage 7)
*Interactive selection. Not pre-installed by default (Opt-in).*

| Category | Apps |
|----------|------|
| **Browsers** | Firefox, Google Chrome, Ungoogled Chromium, Helium |
| **Dev** | Antigravity IDE (`antigravity-bin`) |
| **Office** | OnlyOffice (`onlyoffice-bin`) |
| **Chat** | Signal Desktop |
| **Media** | VLC |

### 4. Workspaces (Stage 8)
*Automated container environments: `ai-lab` and `dev-lab`.*

| Workspace | Base Image | Packages Installed |
|-----------|------------|--------------------|
| **ai-lab** | Arch Linux | `rocm-hip-sdk` (v7.1+), `python-pytorch-rocm`, `python-numpy` |
| **dev-lab** | Arch Linux | `base-devel`, `git`, `rust`, `go`, `nodejs`, `npm`, `python` |

---

## Appendix B: Troubleshooting

### Can't boot from USB
- Check BIOS boot order.
- Try different USB port.
- Recreate Ventoy USB.

### No display after install
- Boot with `nomodeset` parameter.
- Run graphics setup script to install proper drivers.

### Script fails
1.  **AI Diagnosis**: Look for the specialized AI log:
    - `~/strix-halo-setup/logs/[stage].ai-context.log`
    - Contains: System Info + Failed Command + Last 50 lines of output.
    - **Action**: Copy text -> Paste to Gemini/Claude.

2.  **Resume Support**: You don't need to re-run successful steps.
    - Run the specific stage script with `RESUME_STEP` variable.
    - Example: `sudo RESUME_STEP=3 ./stages/04-lxd-setup.sh` (Skips steps 1-2).

### System won't boot after script changes
1. Boot from Ventoy USB (CachyOS live).
2. Mount your installed system.
3. Chroot and fix the issue.
4. Check kernel logs: `journalctl -xb`

---
**CachyOS Strix Halo Guide** | Version 2025.12.11 | Dave Weinstein (@daveweinstein1)
