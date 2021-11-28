#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

# Main
MainPath="$(pwd)"
MainClangPath="${MainPath}/clang"
MainClangZipPath="${MainPath}/clang-zip"
ClangPath=${MainClangZipPath}
GCCaPath="${MainPath}/GCC64"
GCCbPath="${MainPath}/GCC32"
MainZipGCCaPath="${MainPath}/GCC64-zip"
MainZipGCCbPath="${MainPath}/GCC32-zip"

CloneKernel(){
    git clone --depth=1 https://github.com/kentanglu/Rocket_Kernel_MT6768 -b eleven merlin
}

CloneFourteenGugelClang(){
    ClangPath=${MainClangZipPath}
    [[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
    mkdir $ClangPath
    rm -rf $ClangPath/*
    if [ ! -e "${MainPath}/clang-r437112.tar.gz" ];then
        wget -q  https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/3a785d33320c48b09f7d6fcf2a37fed702686fdc/clang-r437112.tar.gz -O "clang-r437112.tar.gz"
    fi
    tar -xf clang-r437112.tar.gz -C $ClangPath
    TypeBuilder="GCLANG-14"
    ClangType="$(${ClangPath}/bin/clang --version | head -n 1)"
}

CloneCompiledGccTwelve(){
        git clone https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 12 $GCCaPath --depth=1
        git clone https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 12 $GCCbPath --depth=1
}

#Main2
KERNEL_ROOTDIR=$(pwd)/merlin # IMPORTANT ! Fill with your kernel source root directory.
export KERNELNAME=Sea-Kernel
export KBUILD_BUILD_USER=Asyanx # Change with your own name or else.
export KBUILD_BUILD_HOST=#ZpyLab # Change with your own hostname.
IMAGE=$(pwd)/merlin/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date +"%F-%S")
START=$(date +"%s")
PATH=${ClangPath}/bin:${GCCaPath}/bin:${GCCbPath}/bin:/usr/bin:${PATH}

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
    LD_LIBRARY_PATH="${ClangPath}/lib:${LD_LIBRARY_PATH}" \
    CC=clang \
    CROSS_COMPILE=aarch64-zyc-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-zyc-linux-gnueabi- \
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
    zip -r9 $KERNELNAME-[Google0]-$DATE.zip *
    cd ..
}
CloneKernel
CloneFourteenGugelClang
CloneCompiledGccTwelve
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
