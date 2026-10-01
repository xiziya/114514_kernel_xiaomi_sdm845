# MIX 2S HyperOS 4 kernel snapshot

This branch is the complete tracked source used for the local OS409 V1/V1.1
kernel, based on lineage-23.2_xiaomi commit 1f326a9202472e8228c2a08ebfd4fdb83da52675.
It adds the exact resolved build config and a rebuild script. No KSU, SukiSU
or SUSFS integration is enabled in this snapshot.

Changes from the lineage base:
- EROFS inline symlinks crossing metadata page boundaries use the mapped path.
- SELinux netlink_xperm and functionfs_seclabel policy capabilities are backported.
- Global user-visible kernel release and banner are 5.15.221; actual ABI and
  internal UTS_RELEASE/vermagic remain 4.19.325. This is not a 5.15 kernel.
- TAS2557 ioctl magic constant is unsigned to address compiler handling.
- The supplied resolved config enables SDM845, WLAN/QCA_CLD_WLAN, KGSL,
  EROFS, pstore and BPF. Existing konadisp.conf supplies display techpack options.

Build in Ubuntu with the same Android clang r416183b (12.0.5), GNU AArch64
and ARM32 cross-toolchains:

    CLANG_BIN=/path/to/clang-r416183b/bin \
    GCC64_BIN=/usr/bin GCC32_BIN=/usr/bin \
    OUT_DIR=/absolute/path/to/fresh-output \
    bash tools/hyperos4/build-polaris.sh

Output: $OUT_DIR/arch/arm64/boot/Image.gz-dtb (kernel plus device trees).
The config at arch/arm64/configs/hyperos4_polaris_defconfig is the FULL resolved
config from the ROM build, not a minimal fragment. Use the script's olddefconfig
step, not the original vendor defconfig alone. Different compiler probes, Git
revision and build timestamps can change output bytes.

The previous compatibility branch had thermal modifications not present in
this ROM kernel. They are replaced by this source snapshot. Its old tip remains
at hyperos4-thermal-compat-pre-overwrite-20261001 (0153709c54678cb11b0a4f8482088152f4421d1d).

The ROM boot image also includes first-stage static EROFS fstab/ramdisk changes
and removal of lpm_levels.sleep_disabled=1. These are NOT kernel source changes.
When packaging with AnyKernel3, preserve the working ROM boot ramdisk, header,
cmdline, correct appended DTBs and partition layout. Do not substitute an
unrelated boot template or infer GKI compatibility from the spoofed version.

User reports V1.1 reaches the system but has outstanding call/SMS, backlight,
microphone and launcher blur bugs. Those are not claimed fixed by this snapshot.
The SukiSU AK3 reboot cause has not been diagnosed. Integrating SukiSU requires
rebuilding this same base and separately verifying its hooks and packaging.
No phone was flashed by this synchronization. ROM tools/docs remain local.
