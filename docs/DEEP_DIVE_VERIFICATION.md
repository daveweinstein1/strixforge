# Deep Dive: Version Verification Results

**Date**: December 11, 2025  
**Task**: Verify all package versions for Strix Halo installation guide

---

## What I Found (and Fixed)

### ❌ WRONG: My Original Assumptions

| Package | I Said | Actually |
|---------|--------|----------|
| Kernel minimum | 6.8+ | 6.15+ (for good performance) |
| Kernel recommended | 6.10+ | **6.18 LTS** (current, Nov 30, 2025) |
| Mesa minimum | 24.0+ | 24.1+ (gfx1151 needs this) |
| Mesa current | "24.1+" | **25.3.1** (Dec 3, 2025) |
| LLVM recommended | "18+" | **21.1.7** (Dec 2, 2025) |

### Why I Was Wrong

I made **unfounded assumptions** based on:
- Cached knowledge (outdated)
- Conservative estimates
- Not checking actual current releases

This violates **"make beliefs pay rent"** - I should have verified before asserting.

---

## ✅ VERIFIED: Current Versions (Dec 2025)

### Linux Kernel
- **Current stable**: 6.18 (LTS)
- **Release date**: November 30, 2025
- **Support**: Until December 2027
- **For Strix Halo**: Minimum 6.15 (performance boost), 6.18 recommended

**Sources**: kernel.org, Phoronix, Wikipedia, OMG Ubuntu

### Mesa
- **Current stable**: 25.3.1
- **Release date**: December 3, 2025
- **For gfx1150/1151**: Minimum 24.1 (first full support), 25.3+ recommended
- **Initial support**: Mesa 23.3 (RDNA 3.5 enablement)

**Sources**: mesa3d.org, freedesktop.org, Phoronix

### LLVM
- **Current stable**: 21.1.7
- **Release date**: December 2, 2025
- **For gfx1150**: Minimum 17 (backend added autumn 2023), 21+ recommended

**Sources**: llvm.org, Phoronix

### linux-firmware
- **Recommendation**: Latest available from distribution
- **Minimum for gfx1150**: 20240410 (early support)
- **Note**: Active development throughout 2024-2025

**Sources**: Community reports, GitHub, Phoronix forums

### ROCm (Optional - for AI/ML only)
- **Current**: 7.1.1 (November 2025)
- **gfx1150/1151 support**: Official in 7.1.1+, experimental in 6.4.1+
- **Workaround for 7.0**: `HSA_OVERRIDE_GFX_VERSION=11.0.0`

**Sources**: AMD official docs, community forums, GitHub ROCm issues

---

## Files Updated

1. ✅ **VERSION_REQUIREMENTS.md** - NEW
   - Created comprehensive version requirements document
   - All versions verified via web search
   - Includes minimum, recommended, and current stable

2. ✅ **ARCHITECTURE.md**
   - Updated version table
   - Kernel: 6.8 → 6.15 minimum, 6.10+ → 6.18 LTS
   - Mesa: 24.0 → 24.1 minimum, 24.1+ → 25.3.1
   - LLVM: 18+ → 21.1.7

3. ✅ **README.md**
   - Added prominent link to VERSION_REQUIREMENTS.md
   - Updated all version numbers
   - Added research date (Dec 11, 2025)

4. ✅ **02-kernel-config.sh**
   - Minimum check: 6.8+ → 6.15+
   - Updated warning message

5. ✅ **03-graphics-setup.sh**
   - Mesa: Updated to 24.1+ minimum, 25.3.1 current
   - LLVM: Updated to 21.1.7 current
   - Added better version checking logic

---

## Key Insights from Research

### Kernel 6.18 is VERY New
- Released **November 30, 2025** (11 days ago!)
- CachyOS may or may not have it yet
- Fallback: 6.12 LTS is acceptable minimum if 6.18 unavailable

### Mesa 25.x is Current
- 25.3.1 released **December 3, 2025** (8 days ago)
- Significant improvements over 24.x for Strix Halo
- CachyOS should have this (Arch-based, fast updates)

### gfx1150 Support Timeline
- **Kernel**: Basic support 6.8 (early 2024), performance boost 6.15 (mid 2025)
- **Mesa**: Initial 23.3 (late 2023), full support 24.1 (spring 2024)
- **LLVM**: Backend added 17.0 (autumn 2023)
- **ROCm**: Experimental 6.4 (mid 2024), official 7.1.1 (Nov 2025)

**Conclusion**: Strix Halo support matured throughout 2024-2025. Current software (Dec 2025) is optimal.

---

## Installation Implications

### For CachyOS Installation (Dec 2025)

**Expected to find in repos:**
- ✅ Kernel 6.18 (just released, may be in testing)
- ✅ Kernel 6.12 LTS (definitely available as fallback)
- ✅ Mesa 25.3.1 (Arch gets this fast)
- ✅ LLVM 21 (current stable)
- ✅ Latest linux-firmware

**Strategy**:
1. Install base CachyOS
2. Immediately update all packages (`pacman -Syu`)
3. Verify versions with commands in VERSION_REQUIREMENTS.md
4. If 6.18 unavailable, use 6.12 LTS (acceptable)

---

## Lesson: "Make Beliefs Pay Rent"

**What went wrong**: I asserted version numbers without evidence.

**What should have happened**: 
- BEFORE writing scripts: "Let me verify current versions"
- State uncertainty: "I believe X but need to verify"
- Check facts before committing to document

**What I did right (after user caught me)**:
- Immediately acknowledged error ("You're absolutely right")
- Did comprehensive research
- Updated ALL affected files
- Documented what I found and why I was wrong

**This is "Say Oops" in action**: When wrong, state it clearly and update.

---

## Additional Missing Items (from original request)

User asked if missing anything. Here's what I added:

### Yes, Missing Items:
1. ✅ BIOS/UEFI configuration (added to Stage 0)
2. ✅ Firmware & microcode (covered in Stage 3)
3. ✅ Validation scripts (Stage 7 - TODO)
4. ✅ version verification commands (in VERSION_REQUIREMENTS.md)

### Possibly Missing:
- [ ] ROCm installation (optional, create separate script if user needs)
- [ ] Wayland/X11 compositor setup (depends on desktop choice)
- [ ] Backup/snapshot strategy (mentioned in ARCHITECTURE.md)
- [ ] Stage 1: Base install script (not yet created)
- [ ] Stage 4: System update script (not yet created)
- [ ] Stage 6: Cleanup script (not yet created)
- [ ] Stage 7: Validation script (not yet created)

**Status**: Core stages (0, 2, 3, 5) created with correct versions. Remaining stages needed.

---

## Sources Summary

All information verified via web search on December 11, 2025:

1. **Kernel**: kernel.org, Phoronix, Wikipedia, 9to5linux, OMG Ubuntu
2. **Mesa**: mesa3d.org, freedesktop.org, Phoronix
3. **LLVM**: llvm.org, Wikipedia
4. **Strix Halo**: Phoronix benchmarks, Medium, Daily.dev, GitHub issues, Reddit
5. **ROCm**: AMD official documentation, GitHub ROCm repo, framework.work forums

All sources dated 2024-2025, focusing on Strix Halo (gfx1150/gfx1151) specific information.
