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
    git clone --depth=1 $Kernel_source $Kernel_branch $Device_codename
}

CloneFourteenGugelClang(){
    ClangPath=${MainClangZipPath}
    [[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
    mkdir $ClangPath
    rm -rf $ClangPath/*
    if [ ! -e "${MainPath}/clang-r428724.tar.gz" ];then
        wget -q  https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/0625305092d0cfa7e28b0e1b268aff1d3d751eca/clang-r428724/bin.tar.gz -O "clang-r428724.tar.gz"
    fi
    tar -xf clang-r428724.tar.gz -C $ClangPath
    TypeBuilder="GCLANG-13"
    ClangType="$(${ClangPath}/bin/clang --version | head -n 1)"
}

CloneCompiledGccTwelve(){
        git clone https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 12 $GCCaPath --depth=1
        git clone https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 12 $GCCbPath --depth=1
}

#Main2
KERNEL_ROOTDIR=$(pwd)/$Device_codename # IMPORTANT ! Fill with your kernel source root directory.
export KBUILD_BUILD_USER=$Build_user # Change with your own name or else.
export KBUILD_BUILD_HOST=$Build_host # Change with your own hostname.
IMAGE=$(pwd)/merlin/out/arch/arm64/boot/Image.gz
export KBUILD_COMPILER_STRING="with Google clang13"
DATE=$(date +"%F")
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
make -j$(nproc) O=out ARCH=arm64 $Device_defconfig
make -j$(nproc) ARCH=arm64 O=out \
    LD_LIBRARY_PATH="${ClangPath}/lib:${LD_LIBRARY_PATH}" \
    CC=clang \
    AS=llvm-as \
    LD=ld.lld \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
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
    zip -r9 [$KERNELNAME][Google]-$DATE.zip *
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
