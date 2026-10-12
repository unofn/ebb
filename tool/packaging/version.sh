#!/usr/bin/env bash
# 打印 pubspec.yaml 里的版本（去掉 + 号后的构建号）。
#   tool/packaging/version.sh            → 0.1.0
#   tool/packaging/version.sh v0.1.0     → 同上，并检查标签和版本一致，不一致就失败
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
version="$(sed -n 's/^version:[[:space:]]*\([^+[:space:]]*\).*/\1/p' "$root/pubspec.yaml")"
[[ -n "$version" ]] || { echo "pubspec.yaml 里没有 version" >&2; exit 1; }

if [[ $# -gt 0 && "${1#v}" != "$version" ]]; then
  echo "标签 $1 和 pubspec.yaml 的版本 $version 不一致" >&2
  exit 1
fi
echo "$version"
