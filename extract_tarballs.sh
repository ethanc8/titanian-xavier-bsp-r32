#!/bin/bash

# $1 = name of tarball without extension
extract_tbz2() {
    mkdir -p "$1" && cd "$1"
        tar xaf "../$1.tbz2" && rm "../$1.tbz2"
    cd ..
}
cd Linux_for_Tegra
cd kernel
    extract_tbz2 kernel_headers
    extract_tbz2 kernel_supplements
cd ..
cd nv_tegra
    extract_tbz2 config
    extract_tbz2 graphics_demos
    extract_tbz2 nvidia_drivers
    extract_tbz2 weston
cd ..
cd ..

