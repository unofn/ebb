#!/usr/bin/env bash
# 把 `flutter build apk --release` 的产物改名放进 build/dist/，并打印签名证书。
#   tool/packaging/android/package_apk.sh <版本> [--require-release-key]
# 带 --require-release-key 时，APK 是 debug 签名就失败（发布流程用）。
set -euo pipefail

version="$1"
require_release_key="${2:-}"
root="$(cd "$(dirname "$0")/../../.." && pwd)"
apk="$root/build/app/outputs/flutter-apk/app-release.apk"
dist="$root/build/dist"
out="$dist/ebb-$version-android.apk"

mkdir -p "$dist"
cp "$apk" "$out"

sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
apksigner="$(ls -d "$sdk"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1)"
[[ -n "$apksigner" ]] || { echo "找不到 apksigner（Android SDK build-tools）" >&2; exit 1; }
certs="$("$apksigner" verify --print-certs "$out")"
echo "$certs" | grep 'certificate DN'

if [[ "$require_release_key" == "--require-release-key" ]] && grep -q 'CN=Android Debug' <<<"$certs"; then
  echo "APK 用的是 debug 签名，不能发布" >&2
  exit 1
fi
echo "$out"
