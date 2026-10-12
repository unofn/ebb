#!/usr/bin/env bash
# 免安装版：bundle 打成 tar.gz，解压出一个 ebb 文件夹，直接运行里面的 ebb。
#   tool/packaging/linux/package_tarball.sh <版本>   → build/dist/ebb-<版本>-linux-x64.tar.gz
set -euo pipefail

version="$1"
root="$(cd "$(dirname "$0")/../../.." && pwd)"
bundle="$root/build/linux/x64/release/bundle"
dist="$root/build/dist"
out="$dist/ebb-$version-linux-x64.tar.gz"

[[ -x "$bundle/ebb" ]] || { echo "找不到 $bundle/ebb，先运行 flutter build linux --release" >&2; exit 1; }
mkdir -p "$dist"
tar -czf "$out" --owner=0 --group=0 --transform 's,^bundle,ebb,' -C "$(dirname "$bundle")" bundle
echo "$out"
