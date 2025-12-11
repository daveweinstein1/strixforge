# Version Requirements (Strix Halo)
*Verified correct as of December 11, 2025*

| Component | Minimum | Recommended | Reason |
|-----------|---------|-------------|--------|
| **Kernel** | 6.12 | **6.18+ (Bleeding Edge)** | Active Strix Halo Work (NPU/ISP) |
| **Mesa** | 25.0 | **25.3.1+** | GFX1150 Graphics Support |
| **ROCm** | 7.0 | **7.1.1+** | **CRITICAL**: Compute support for Strix Halo |
| **LLVM** | 19.x | **21.x** | Shader Compiler |

> [!IMPORTANT]
> Use CachyOS `v3` or `v4` repositories to ensure you get these bleeding-edge versions. Standard Arch repos may trail behind.
