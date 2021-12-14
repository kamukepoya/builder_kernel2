#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

echo "Downloading few Dependecies . . ."
# Kernel Sources
     git clone --depth=1 $Kernel_source $Kernel_branch $Device_codename
     git clone --depth=1 https://github.com/NusantaraDevs/DragonTC -b daily/10.0 clang
     git clone --depth=1 https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 10 gcc
     git clone --depth=1 https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 10 gcc32

# Main Declaration
KERNEL_ROOTDIR=$(pwd)/merlin
CLANG_ROOTDIR=$(pwd)/clang
export KBUILD_BUILD_USER=Itsprof
export KBUILD_BUILD_HOST=CircleCItod
CLANG_VER="$("$CLANG_ROOTDIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export KBUILD_COMPILER_STRING="$CLANG_VER with $LLD_VER"
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
make -j$(nproc) O=out ARCH=arm64 $Device_defconfig
make -j$(nproc) ARCH=arm64 O=out \
    CC=clang \
    AS=llvm-as \
    LD=ld.lld \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-zyc-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-zyc-linux-gnueabi-

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi
  git clone --depth=1 $Anykernel AnyKernel
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
        -F caption="Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$DEVICE_CODENAME</b> | <b>DTC</b>"
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
    zip -r9 $KERNELNAME-$DATE.zip *
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
