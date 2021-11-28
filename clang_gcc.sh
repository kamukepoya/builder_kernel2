#!/usr/bin/env bash

DATE=$(date +"%F-%S")
START=$(date +"%s")

# Main
MainPath="$(pwd)"
MainClangPath="${MainPath}/clang"
MainClangZipPath="${MainPath}/clang-zip"
ClangPath=${MainClangZipPath}
GCCaPath="${MainPath}/GCC64"
GCCbPath="${MainPath}/GCC32"
MainZipGCCaPath="${MainPath}/GCC64-zip"
MainZipGCCbPath="${MainPath}/GCC32-zip"

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
    [[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
    GCCaPath="${MainGCCaPath}"
    if [ ! -d "$GCCaPath" ];then
        git clone https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 12 $GCCaPath --depth=1
    else
        cd "${GCCaPath}"
        git fetch https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 12 --depth=1
        git checkout FETCH_HEAD
        [[ ! -z "$(git branch | grep 12)" ]] && git branch -D 12
        git checkout -b 12
    fi
    for64=aarch64-zyc-linux-gnu
    [[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
    GCCbPath="${MainGCCbPath}"
    if [ ! -d "$GCCbPath" ];then
        git clone https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 12 $GCCbPath --depth=1
    else
        cd "${GCCbPath}"
        git fetch https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 12 --depth=1
        git checkout FETCH_HEAD
        [[ ! -z "$(git branch | grep 12)" ]] && git branch -D 12
        git checkout -b 12
    fi
    for32=arm-zyc-linux-gnueabi
}
END=$(date +"%s")
DIFF=$(($END - $START))
