# Strix Halo Go Post-Installer — Implementation Plan

*Updated: January 9, 2026*
*Platform: AMD Strix Halo (gfx1151) on CachyOS*

---

## 1. Architecture Overview

```
strix-installer/
├── cmd/
│   ├── tui/main.go          # Unified entry point (TUI + Browser Web UI)
│   └── gui/main.go          # (Deprecated - Wails approach abandoned)
├── pkg/
│   ├── core/                 # Platform-agnostic installer engine
│   │   ├── engine.go         # Main orchestrator
│   │   ├── stage.go          # Stage interface + runner
│   │   └── events.go         # Progress/log events
│   ├── platform/             # Platform-specific implementations
│   │   ├── platform.go       # Platform interface
│   │   ├── strixhalo/        # Strix Halo implementation
│   │   │   ├── detect.go     # Hardware detection
│   │   │   ├── stages.go     # All 9 stages
│   │   │   └── devices/      # Device-specific quirks
│   │   │       ├── beelink.go
│   │   │       ├── framework.go
│   │   │       └── minisforum.go
│   │   └── generic/          # Future: generic Arch installer
│   ├── system/               # OS interaction layer
│   │   ├── pacman.go         # Package management
│   │   ├── systemd.go        # Service management
│   │   ├── grub.go           # Bootloader
│   │   └── lxd.go            # Container management
│   └── ui/                   # Shared UI abstractions
│       ├── progress.go       # Progress reporting interface
│       └── prompt.go         # User input interface
├── frontend/                 # Web assets (HTML/JS/CSS)
│   ├── index.html
│   ├── app.js
│   └── style.css
├── configs/                  # Platform/device configs
│   ├── strixhalo.yaml
│   └── devices/
│       ├── beelink-gtr9.yaml
│       ├── framework-desktop.yaml
│       └── minisforum-s1max.yaml
└── go.mod
```

---

## 2. Core Interfaces

### 2.1 Platform Interface
```go
type Platform interface {
    Name() string
    Detect() (Device, error)
    Stages() []Stage
    Validate() error
}

type Device interface {
    Name() string
    Manufacturer() string
    Model() string
    Quirks() []Quirk
}

type Quirk struct {
    ID          string
    Description string
    Apply       func(ctx context.Context) error
}
```

### 2.2 Stage Interface
```go
type Stage interface {
    ID() string
    Name() string
    Description() string
    Run(ctx context.Context, ui UI) error
    Rollback(ctx context.Context) error
    Skip() bool
}

type StageResult struct {
    StageID  string
    Status   Status  // Success, Failed, Skipped
    Duration time.Duration
    Error    error
    Logs     []LogEntry
}
```

### 2.3 UI Interface
```go
type UI interface {
    // Progress
    StageStart(stage Stage)
    StageComplete(result StageResult)
    Progress(percent int, message string)
    
    // Logging
    Log(level Level, message string)
    
    // Prompts
    Confirm(message string, defaultYes bool) bool
    Select(message string, options []string) int
    Input(message string, defaultVal string) string
}
```

---

## 3. Implementation Phases (Completed)

### Phases 1-9: Core Functions ✅

**Stage 1: `kernel`**
- Backup `/etc/default/grub`
- Check for Kernel 6.18+ (required for NPU/gfx1151 fixes)
- Apply `iommu=pt` and `amd_pstate=active` params
- Apply device quirks (e.g., Beelink E610 blacklist)

**Stage 2: `graphics`**
- Install Mesa 25.3+, Vulkan-Radeon, LLVM 21.x
- Verify `linux-firmware` is 20250108+

**Stage 3: `system`**
- Run `cachyos-rate-mirrors`
- Perform full `pacman -Syu`
- Install essentials: `base-devel`, `git`, `wget`, `curl`, `vim`, `btop`

**Stage 4: `lxd`**
- Install `lxd` package
- Initialize with `lxd init --auto`
- Enable `security.nesting=true`
- Add `gpu0` device to default profile (GID 110)

**Stage 5: `thermal`**
- Install `lm_sensors`, `fancontrol`
- Apply fail-safe fan curve for Strix Halo chips

**Stage 6: `cleanup`**
- Remove orphans: `pacman -Rns $(pacman -Qtdq)`
- Clear package cache: `pacman -Scc`

**Stage 7: `validate`**
- Check `uname -r` (6.18+)
- Check `glxinfo` (AMD renderer)
- Check `lxd.socket` status

**Stage 8: `apps` (Optional)**
- Browsers: `firefox`
- Messaging: `signal-desktop`
- Media: `vlc`

**Stage 9: `workspace` (Optional)**
- Create `ai-lab` container (ROCm 7.2, PyTorch, Ollama)
- Create `dev-lab` container (Rust, Go, Node, Python)

### Phase 10: Container Lifecycle Management ✅

Implemented in `pkg/system/lxd.go`:
- **Snapshot Creation:** `CreateSnapshot(ctx, container, snapshotName)`
- **Restore:** `RestoreSnapshot(ctx, container, snapshotName)`
- **Recreate:** `RecreateContainer(ctx, name, image)` (Delete + Create)
- **Status:** `GetContainerStatus(ctx, name)` monitors state

### Phase 11: Version Verification ✅

Implemented in `pkg/system/versions.go`:
- **Comparison Engine:** `CheckAllVersions(ctx)` compares installed vs expected
- **Table Output:** `FormatVersionTable(checks)` renders ASCII table
- **Logic:** Handles OK, Newer, Older, and Missing states
- **Overrides:** User prompts when critical versions are older than expected

### Phase 12: Auto/Manual Install Mode ✅

Implemented in `cmd/tui/main.go`:
- **Auto Mode (`--auto`):** Runs all enabled stages sequentially without prompts.
- **Manual Mode (`--manual`):** Launches TUI menu to select specific stages.
- **Dry Run (`--dry-run`):** Simulates execution, logging actions without changes.
- **Check Versions (`--check-versions`):** Runs Phase 11 check and exits.

### Phase 13: Bootstrap & Short URL

- [x] `install.sh` bootstrap script created
- [x] Downloads latest release from GitHub
- [ ] bit.ly/strix-halo short URL pending setup

---

## 4. New Phases (Planned)

### Phase 14: ZRAM Optimization 🚧

**Goal:** Disable ZRAM on high-memory (64GB+) Strix Halo systems to prevent GTT conflicts.

- [ ] **Detection:** Check RAM > 64GB
- [ ] **Action:** `systemctl disable --now zram-generator@zram0.service`
- [ ] **Integration:** Add to `thermal` or `system` stage

### Phase 15: kyuz0 Container Marketplace 🚧

**Goal:** Graphical browser for kyuz0's toolbox images, installing them into LXD.

- [ ] **GHCR API Client:** Fetch image tags from `ghcr.io/kyuz0/amd-strix-halo-toolboxes`
- [ ] **TUI Browser:** List view with scrolling and selection
- [ ] **Web UI Card View:** Grid of available tools (LLaMA, ComfyUI, etc.)
- [ ] **Install Action:** Execute `toolbox create` inside the `ai-lab` container

### Phase 16: Web UI Frontend 🚧

**Goal:** Create actual HTML/JS assets for the browser mode (currently loads blank).

- [ ] **Frontend Assets:** Populate `frontend/` with `index.html`, `app.js`, `style.css`
- [ ] **Progress Sync:** Implement WebSocket/SSE to pipe TUI events to Web UI
- [ ] **Device Dashboard:** Show detected hardware and applied quirks
- [ ] **Controls:** Pause/Resume, Stage toggles

### Phase 17: Wails Native GUI (Cancelled) ❌

*Decision: Abandoned in favor of browser app mode to save development time and binary size.*

---

## 5. Application Categories (Config-Driven)

```go
// pkg/platform/strixhalo/detect.go
func Detect() (Device, error) {
    manufacturer := dmidecode("system-manufacturer")
    product := dmidecode("system-product-name")
    
    switch {
    case strings.Contains(manufacturer, "Beelink"):
        return &BeelinkGTR9{}, nil
    case strings.Contains(manufacturer, "Framework"):
        return &FrameworkDesktop{}, nil
    case strings.Contains(manufacturer, "Minisforum"):
        return &MinisforumS1Max{}, nil
    default:
        return &GenericStrixHalo{}, nil
    }
}
```

---

## 6. Device Quirks

### Beelink GTR9 Pro
```yaml
quirks:
  - id: e610-blacklist
    description: "Blacklist Intel E610 Ethernet driver (crashes under GPU load)"
    kernel_params: ["modprobe.blacklist=ice"]
  - id: tdp-tool
    description: "Install TDP control utility"
    packages: ["ryzenadj"]
```

### Framework Desktop
```yaml
quirks:
  - id: fan-noise
    description: "Recommend BIOS TDP reduction (140W → 110W)"
    type: advisory
```

### Minisforum MS-S1 Max
```yaml
quirks:
  - id: ethernet-broken
    description: "Onboard Ethernet unreliable, recommend USB adapter"
    type: advisory
  - id: usb4-display
    description: "USB4 display output may not work, use HDMI"
    type: advisory
```

---

## 7. Configuration Format

```yaml
# configs/strixhalo.yaml
platform:
  name: "Strix Halo"
  codename: "gfx1151"

requirements:
  kernel: "6.18"
  mesa: "25.3"
  rocm: "7.2"
  llvm: "21"

stages:
  - id: kernel
    enabled: true
  - id: graphics
    enabled: true
  - id: system
    enabled: true
  - id: lxd
    enabled: true
  - id: cleanup
    enabled: true
  - id: validate
    enabled: true
  - id: apps
    enabled: true
    optional: true
  - id: workspace
    enabled: true
    optional: true
```

---

## 8. Event System

```go
// pkg/core/events.go
type Event interface{}

type StageStarted struct { Stage Stage }
type StageCompleted struct { Stage Stage; Result StageResult }
type ProgressUpdate struct { Percent int; Message string }
type LogMessage struct { Level Level; Message string }
type PromptRequest struct { Type PromptType; Message string; Response chan interface{} }
```

Both TUI and Web UI subscribe to these events to update their displays.

---

## 9. Build Outputs

| Binary | Size | Use Case |
|--------|------|----------|
| `strix-install` | ~10 MB | Unified Binary (TUI + Browser Web UI) |

**Build Command:**
```bash
go build -ldflags="-s -w" -o strix-install ./cmd/tui
```

---

## 10. Extensibility Mechanism

To add support for a new distro (e.g., Fedora):
1. Implement `pkg/system/PackageManager` interface (dnf vs pacman)
2. Create `configs/fedora.yaml`
3. The core engine remains unchanged

---

## 11. Success Metrics

- **v1.0:** Installs successfully on Framework Desktop + Beelink GTR9
- **v1.1:** Web UI fully implemented
- **v1.2:** kyuz0 marketplace integration
- **Adoption:** 50+ successful installs validated by community
