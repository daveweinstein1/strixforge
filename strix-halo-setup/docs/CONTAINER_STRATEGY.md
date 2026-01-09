# Container Strategy: ai-lab & dev-lab

*Why we use isolated LXD containers for AI and development workloads*

---

## The Problem: Bleeding Edge is Fragile

### AI Infrastructure (ai-lab)

AMD's ROCm ecosystem for consumer GPUs like Strix Halo (gfx1151) is in a **"wild west" development state**:

- **Rapid breaking changes** — ROCm 7.x is actively developed with weekly updates
- **Unofficial support** — gfx1151 support is community-driven, not Tier 1
- **Library conflicts** — PyTorch, TensorFlow, and ONNX may require conflicting versions
- **LLVM dependencies** — ROCm ships its own LLVM that may clash with system LLVM
- **Kernel module issues** — amdgpu driver updates can break ROCm silently

**Real-world scenario:** You install a ComfyUI node that pulls a specific PyTorch version. That version requires a different ROCm runtime. Now nothing works, and `pip uninstall` doesn't fully clean up the mess.

### Development Tools (dev-lab)

AI-assisted coding tools are equally unstable:

- **VS Code Copilot** updates that break extensions
- **Cursor/Windsurf** constant experimental features
- **Continue.dev** rapid iteration with breaking changes
- **Local LLM integrations** (Ollama, LM Studio) version sensitivity

**Real-world scenario:** You try a new AI coding extension that modifies your settings. After uninstalling, your LSP configurations are corrupted.

---

## The Solution: Container Isolation + Snapshots

### Architecture

```
Host (CachyOS)
├── Graphics stack (Mesa, Vulkan) — stable, rarely changes
├── LXD service
│
├── ai-lab (LXD container)
│   ├── ROCm 7.2
│   ├── PyTorch
│   ├── ComfyUI
│   └── [SNAPSHOTS: clean, working-v1, pre-experiment]
│
└── dev-lab (LXD container)
    ├── Rust, Go, Node, Python
    ├── Antigravity/Cursor/etc.
    └── [SNAPSHOTS: clean, my-setup, pre-update]
```

### Key Benefits

| Benefit | Description |
|---------|-------------|
| **Isolation** | Container breakage doesn't affect host or other containers |
| **Snapshots** | Instant rollback to any saved state |
| **Fresh start** | Delete and recreate container in minutes |
| **GPU passthrough** | Full hardware acceleration inside containers |
| **Reproducibility** | Share exact container state with others |

---

## LXD Snapshot Workflow

### Creating Snapshots

```bash
# Save current state
lxc snapshot ai-lab clean
lxc snapshot ai-lab working-v1
lxc snapshot ai-lab pre-experiment

# List snapshots
lxc info ai-lab | grep -A100 Snapshots
```

### Restoring Snapshots

```bash
# Rollback to previous state (DESTRUCTIVE - current state lost)
lxc restore ai-lab working-v1

# Or restore to a new container (keeps current)
lxc copy ai-lab/working-v1 ai-lab-restored
```

### Fresh Start

```bash
# Nuclear option: delete and recreate
lxc delete ai-lab --force
lxc launch images:archlinux ai-lab
# Re-run installer workspace stage
```

---

## Installer Options

The Strix Halo installer provides these container options:

### First Run
- **Create ai-lab** — Fresh Arch container with ROCm stack
- **Create dev-lab** — Fresh Arch container with dev tools
- Automatic snapshot named `clean` created after initial setup

### Subsequent Runs
- **Restore snapshot** — Pick from available snapshots
- **Delete and recreate** — Fresh start, loses all data
- **Update packages** — Run package updates in existing container
- **Skip** — Don't touch containers

---

## When to Use Each Option

| Situation | Action |
|-----------|--------|
| "I broke something, want to undo" | Restore last good snapshot |
| "Installing experimental package" | Create snapshot first, then install |
| "Container is completely borked" | Delete and recreate |
| "Just want latest packages" | Update packages |
| "Everything is working fine" | Skip |

---

## Best Practices

1. **Snapshot before experiments** — Always `lxc snapshot ai-lab pre-experiment` before trying new packages
2. **Name snapshots meaningfully** — `working-comfyui-v1` not `backup3`
3. **Clean up old snapshots** — They consume disk space
4. **Document your working state** — What packages/versions are in your `working` snapshot

---

## Disk Space Considerations

LXD snapshots use copy-on-write with ZFS/btrfs, so they're efficient:

- **Initial snapshot**: ~0 bytes (just metadata)
- **After changes**: Only changed blocks stored
- **Typical ai-lab**: 5-15 GB base, 1-3 GB per snapshot with changes

Check usage:
```bash
lxc storage info default
```
