# Complete Package Inventory
*Strix Halo Post-Install Scripts - January 2026*

## Host System Packages

### Stage 02: Graphics Stack
```
mesa lib32-mesa mesa-utils
vulkan-radeon lib32-vulkan-radeon vulkan-tools
linux-firmware
llvm lib32-llvm
```

### Stage 03: System Essentials
```
base-devel git wget curl vim neovim btop neofetch fastfetch
```

### Stage 04: Containers
```
lxd
```

### Stage 07: User Applications

**Official Repos (pacman):**
```
firefox signal-desktop vlc yay
```

**AUR (yay):**
```
google-chrome ungoogled-chromium-bin helium
antigravity-bin onlyoffice-bin
```

---

## Container Packages

### ai-lab (LXD Container)
```
rocm-hip-sdk python-pytorch-rocm python-numpy python-pip
git base-devel fastfetch vim
```

### dev-lab (LXD Container)
```
base-devel git rust go nodejs npm
python python-pip vim neovim fastfetch
```

---

## Summary Count

| Category | Count |
|----------|-------|
| Host: Official Repos | 21 packages |
| Host: AUR | 5 packages |
| Container: ai-lab | 8 packages |
| Container: dev-lab | 11 packages |
| **Total** | **45 packages** |
