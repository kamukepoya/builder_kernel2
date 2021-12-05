#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

#clear
clear() {
        - rm -rf merlin AnyKernel clang GCC64 GCC32 \
        - sleep 30s
}

# Kernel Sources
KernelSource() {
     git clone --depth=1 $Kernel_source $Kernel_branch $Device_codename
     git clone --depth=1 https://github.com/GengKapak/GengKapak-clang -b 12 clang
}

# Main Declaration
KERNEL_ROOTDIR=$(pwd)/$Device_codename # IMPORTANT ! Fill with your kernel source root directory.
CLANG_ROOTDIR=$(pwd)/clang # IMPORTANT! Put your clang directory here.
export KBUILD_BUILD_USER=$Build_user # Change with your own name or else.
export KBUILD_BUILD_HOST=$Build_host # Change with your own hostname.
export KBUILD_COMPILER_STRING="With GengKapak clang"
IMAGE=$(pwd)/merlin/out/arch/arm64/boot/Image.gz
DATE=$(date +"%F")
START=$(date +"%s")
PATH="${PATH}:$(pwd)/clang/bin"

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"

}

# Compile
compile(){
cd ${KERNEL_ROOTDIR}
make -j$(nproc) O=out ARCH=arm64 $Device_defconfig
make -j$(nproc) ARCH=arm64 O=out \
    CC=${CLANG_ROOTDIR}/bin/clang \
    NM=${CLANG_ROOTDIR}/bin/llvm-nm \
    LD=${CLANG_ROOTDIR}/bin/ld.lld \
    CROSS_COMPILE=${CLANG_ROOTDIR}/bin/aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=${CLANG_ROOTDIR}/bin/arm-linux-gnueabi-

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi
  git clone --depth=1 $ANYKERNEL AnyKernel
	cp $IMAGE AnyKernel
}

# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$DEVICE_CODENAME</b> | <b>${KBUILD_COMPILER_STRING}</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 [GengKapak][$KERNELNAME]-kernel-[$DATE].zip *
    cd ..
}
clear
KernelSource
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
