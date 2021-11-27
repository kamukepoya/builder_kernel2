#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

# Needed Secret Variable
# DEVICE_CODENAME | Your device codename
# TG_TOKEN | Your telegram bot token
# TG_CHAT_ID | Your telegram private ci chat id

echo "Downloading few Dependecies . . ."
# Kernel Sources
git clone --depth=1 https://github.com/kentanglu/Rocket_Kernel_MT6768 -b eleven merlin
    mkdir clang
    if [ ! -e "clang/clang-r433403.tar.gz" ];then
        wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/3a785d33320c48b09f7d6fcf2a37fed702686fdc/clang-r437112.tar.gz -O clang-r437112.tar.gz
    fi
    tar -xf clang-r433403.tar.gz -C clang
    mkdir gcc
    mkdir gcc32
    if [ ! -e "gcc32/arm-linux-gnueabi-10.x-gnu-20210311.tar.gz" ];then
        wget -q https://gcc-drive.zyc-files.workers.dev/0:/arm-linux-gnueabi-10.x-gnu-20210311.tar.gz
    fi
    tar -xf arm-linux-gnueabi-10.x-gnu-20210311.tar.gz -C gcc32
    if [ ! -e "gcc/aarch64-linux-gnu-10.x-gnu-20210311.tar.gz" ];then
        wget -q https://gcc-drive.zyc-files.workers.dev/0:/aarch64-linux-gnu-10.x-gnu-20210311.tar.gz
    fi
    tar -xf aarch64-linux-gnu-10.x-gnu-20210311.tar.gz -C gcc

# Main Declaration
KERNEL_ROOTDIR=$(pwd)/merlin # IMPORTANT ! Fill with your kernel source root directory.
export KERNELNAME=Sea-Kernel
CLANG_ROOTDIR=$(pwd)/clang
export KBUILD_BUILD_USER=Asyanx # Change with your own name or else.
export KBUILD_BUILD_HOST=#ZpyLab # Change with your own hostname.
CLANG_VER="$("$CLANG_ROOTDIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/ */ /g' -e 's/[[:space:]]*$//')"
IMAGE=$(pwd)/merlin/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date +"%F-%S")
START=$(date +"%s")
PATH="$(pwd)/clang/bin:$(pwd)/gcc/bin:$(pwd)/gcc32/bin:${PATH}"

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
make -j$(nproc) O=out ARCH=arm64 merlin_defconfig
make -j$(nproc) ARCH=arm64 O=out \
CC=${CLANG_ROOTDIR}/bin/clang \
NM=${CLANG_ROOTDIR}/bin/llvm-nm \
CROSS_COMPILE=aarch64-linux-gnu-- \ 
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \ 
CLANG_TRIPLE=aarch64-linux-gnu-

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
        -F caption="Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$DEVICE_CODENAME</b> | [GCC] TEST</b>"
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
    zip -r9 $KERNELNAME-[G]-$DATE.zip *
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
