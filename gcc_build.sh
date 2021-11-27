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
     git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 gcc-arm64 
     git clone --depth=1 https://github.com/mvaisakh/gcc-arm gcc-arm


# Main Declaration
KERNEL_ROOTDIR=$(pwd)/merlin # IMPORTANT ! Fill with your kernel source root directory.
GCC64_ROOTDIR=$(pwd)/gcc-arm64 # IMPORTANT! Put your gcc64 directory here.
GCC32_ROOTDIR=$(pwd)/gcc-arm # IMPORTANT! Put your gcc32 directory here.
export KERNELNAME=Sea-Kernel
export KBUILD_BUILD_USER=Asyanx # Change with your own name or else.
export KBUILD_BUILD_HOST=#ZpyLab # Change with your own hostname.
GCC_VER="$("$GCC64_ROOTDIR"/bin/aarch64-elf-gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
LLD_VER="$("$GCC64_ROOTDIR"/bin/ld.lld --version | head -n 1)"
IMAGE=$(pwd)/merlin/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date +"%F-%S")
START=$(date +"%s")
PATH="${PATH}:${GCC64_ROOTDIR}/bin:${GCC32_ROOTDIR}/bin"

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
    LD=${GCC64_ROOTDIR}/bin/ld.lld \
    CROSS_COMPILE=${GCC64_ROOTDIR}/bin/aarch64-elf- \
    CROSS_COMPILE_ARM32=${GCC32_ROOTDIR}/bin/arm-eabi-

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
    zip -r9 $KERNELNAME-[GCC]-$DATE.zip *
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
