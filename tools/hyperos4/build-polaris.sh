#!/usr/bin/env bash
set -euo pipefail
: "${CLANG_BIN:?Set CLANG_BIN to clang-r416183b/bin}"
: "${GCC64_BIN:?Set GCC64_BIN to GNU AArch64 toolchain bin}"
: "${GCC32_BIN:?Set GCC32_BIN to GNU ARM32 toolchain bin}"
: "${OUT_DIR:?Set OUT_DIR to a fresh absolute build directory}"
case "$OUT_DIR" in /*) ;; *) echo "OUT_DIR must be absolute" >&2; exit 2;; esac
kernel_source=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
if [[ -e "$OUT_DIR/.config" ]]; then
    echo "OUT_DIR already contains a config; use a fresh directory to preserve it" >&2
    exit 2
fi
mkdir -p "$OUT_DIR"
export PATH="$CLANG_BIN:$GCC64_BIN:$GCC32_BIN:$PATH"
python3 "$kernel_source/tools/hyperos4/check-configs.py"     "$kernel_source/arch/arm64/configs/hyperos4_polaris_defconfig"     "$kernel_source/arch/arm64/configs/vendor/xiaomi/polaris.config"
bash "$kernel_source/scripts/kconfig/merge_config.sh" -m -O "$OUT_DIR"     "$kernel_source/arch/arm64/configs/hyperos4_polaris_defconfig"     "$kernel_source/arch/arm64/configs/vendor/xiaomi/polaris.config"
make_args=(-C "$kernel_source" "O=$OUT_DIR" ARCH=arm64 "CC=$CLANG_BIN/clang"
    CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu-
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- LD=ld.lld AR=llvm-ar NM=llvm-nm
    OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip)
make "${make_args[@]}" olddefconfig
python3 "$kernel_source/tools/hyperos4/check-configs.py"     "$kernel_source/arch/arm64/configs/hyperos4_polaris_defconfig"     "$kernel_source/arch/arm64/configs/vendor/xiaomi/polaris.config" "$OUT_DIR/.config"
for option in ARCH_SDM845 WLAN QCA_CLD_WLAN QCOM_KGSL PSTORE PSTORE_RAM EROFS_FS BPF_SYSCALL; do
    grep -qx "CONFIG_$option=y" "$OUT_DIR/.config" || { echo "Missing $option" >&2; exit 1; }
done
if grep -Eq '^CONFIG_.*(KSU|KERNELSU|SUKISU|SUSFS).*=([ym]|[1-9][0-9]*)$' "$OUT_DIR/.config"; then
    echo "This baseline build is intentionally root-free; review root integration separately" >&2
    exit 1
fi
make "${make_args[@]}" -j"${JOBS:-4}" Image.gz-dtb 2>&1 | tee "$OUT_DIR/hyperos4-build.log"
sha256sum "$OUT_DIR/arch/arm64/boot/Image.gz-dtb" "$OUT_DIR/.config"
