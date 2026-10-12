#!/usr/bin/env bash
# 把 `flutter build macos --release` 的 Ebb.app 做成 dmg：里面放 Ebb.app
# 和一个指向 /Applications 的快捷方式，拖进去就装好。
#   tool/packaging/macos/package_dmg.sh <版本>   → build/dist/ebb-<版本>-macos.dmg
set -euo pipefail

version="$1"
root="$(cd "$(dirname "$0")/../../.." && pwd)"
app="$root/build/macos/Build/Products/Release/Ebb.app"
dist="$root/build/dist"
out="$dist/ebb-$version-macos.dmg"

[[ -d "$app" ]] || { echo "找不到 $app，先运行 flutter build macos --release" >&2; exit 1; }
# 安装包要同时支持 Intel 和 Apple 芯片。
archs="$(lipo -archs "$app/Contents/MacOS/Ebb")"
[[ "$archs" == *x86_64* && "$archs" == *arm64* ]] || { echo "Ebb 不是通用二进制：$archs" >&2; exit 1; }

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/Ebb.app"
ln -s /Applications "$stage/Applications"

mkdir -p "$dist"
rm -f "$out"
hdiutil create -volname "Ebb $version" -srcfolder "$stage" -fs HFS+ -format UDZO -ov "$out" >/dev/null
echo "$out"
