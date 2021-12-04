#!/bin/bash

START=$(date +"%s")

source() {
        source compiler/clang/Gclang.sh
        source compiler/clang/GPKclang.sh
}
source

END=$(date +"%s")

DIFF=$(( END - START ))

