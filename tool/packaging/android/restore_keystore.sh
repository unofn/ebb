#!/usr/bin/env bash
# 发布流程用：从 GitHub Secrets 还原签名密钥，写出 android/key.properties。
# 需要环境变量 ANDROID_KEYSTORE_BASE64、ANDROID_KEYSTORE_PASSWORD、
# ANDROID_KEY_ALIAS、ANDROID_KEY_PASSWORD；缺任何一个都直接失败，
# 不能退回 debug 签名发布出去。
set -euo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd)"
for name in ANDROID_KEYSTORE_BASE64 ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD; do
  if [[ -z "${!name:-}" ]]; then
    echo "缺少 Secret：$name" >&2
    exit 1
  fi
done

# storeFile 相对 android/app 解析。
echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode >"$root/android/ebb-release.jks"
cat >"$root/android/key.properties" <<PROPS
storeFile=../ebb-release.jks
storePassword=$ANDROID_KEYSTORE_PASSWORD
keyAlias=$ANDROID_KEY_ALIAS
keyPassword=$ANDROID_KEY_PASSWORD
PROPS
echo "已写入 android/key.properties"
