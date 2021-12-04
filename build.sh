#!/bin/bash

export KERNELNAME=Sea-Kernel

tg_post_msg "⏳ Start building ${KERNELNAME} | DEVICE: Merlinx / Merlin"

START=$(date +"%s")

#com
com() {
        - bash compiler/clang/Gclang.sh
        - bash compiler/clang/GPKclang.sh
}
com
END=$(date +"%s")

DIFF=$(( END - START ))

tg_post_msg "✅ Build completed in $((DIFF / 60))m $((DIFF % 60))s"

