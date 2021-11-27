#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

# Main Declaration
MainPath="$(pwd)"
MainClangPath="${MainPath}/Clang"
MainClangZipPath="${MainPath}/Clang-zip"
MainGCCaPath="${MainPath}/GCC64"
MainGCCbPath="${MainPath}/GCC32"
MainZipGCCaPath="${MainPath}/GCC64-zip"
MainZipGCCbPath="${MainPath}/GCC32-zip"
ARCH="arm64"
DEFFCONFIG="merlin_defconfig"
KERNEL_ROOTDIR=$(pwd)/merlin # IMPORTANT ! Fill with your kernel source root directory.
export KERNELNAME=Sea-Kernel
export KBUILD_BUILD_USER=Asyanx # Change with your own name or else.
export KBUILD_BUILD_HOST=#ZpyLab # Change with your own hostname.
DATE=$(date +"%F-%S")
START=$(date +"%s")

echo "Downloading few Dependecies . . ."
# Kernel Sources
git clone --depth=1 https://github.com/kentanglu/Rocket_Kernel_MT6768 -b eleven merlin
git clone https://github.com/Asyanx/AnyKernel3.1 AnyKernel
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
    [[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
    GCCaPath="$MainZipGCCaPath"
    GCCbPath="$MainZipGCCbPath"
    mkdir "${GCCaPath}"
    mkdir "${GCCbPath}"
    rm -rf ${GCCaPath}/* ${GCCbPath}/*
    if [ ! -e "${MainPath}/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz" ];then
        wget -q https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz
        tar -xf gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz -C $GCCbPath
    fi
    GCCbPath="${GCCbPath}/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf"
    for32=arm-none-linux-gnueabihf
    if [ ! -e "${MainPath}/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz" ];then
        wget -q https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz
        tar -xf gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz -C $GCCaPath
    fi
    GCCaPath="${GCCaPath}/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf"
    for64=aarch64-none-elf

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"

}

# Compile
function compile(){
    cd "${KERNEL_ROOTDIR}"
    SendInfoLink
    make    -j${TotalCores}  O=out ARCH="$ARCH" "$DEFFCONFIG"
    if [ -d "${ClangPath}/lib64" ];then
        MAKE=(
                ARCH=$ARCH \
                SUBARCH=$ARCH \
                PATH=${ClangPath}/bin:${GCCaPath}/bin:${GCCbPath}/bin:/usr/bin:${PATH} \
                LD_LIBRARY_PATH="${ClangPath}/lib64:${LD_LIBRARY_PATH}" \
                CC=clang \
                CROSS_COMPILE=$for64- \
                CROSS_COMPILE_ARM32=$for32- \
                AS=llvm-as \
                NM=llvm-nm \
                STRIP=llvm-strip \
                OBJDUMP=llvm-objdump \
                OBJSIZE=llvm-size \
                READELF=llvm-readelf \
                HOSTCC=clang \
                HOSTCXX=clang++ \
                HOSTAR=llvm-ar \
                HOSTLD=ld.lld \
                LD=ld.lld \
                CLANG_TRIPLE=aarch64-linux-gnu-
}

# Push kernel to channel
function push()
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" 


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
