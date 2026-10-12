#!/usr/bin/env bash
# 用 .github/release-notes.md 生成这一版的发布说明，打印到标准输出。
#   tool/packaging/release_notes.sh <版本> [标签]
# 第一行是一句话概括，新版本检查会把它显示给用户：取带注释标签的标题
# （git tag -a v0.1.0 -m "…"），没有就写「Ebb <版本>」。
set -euo pipefail

version="$1"
tag="${2:-v$version}"
root="$(cd "$(dirname "$0")/../.." && pwd)"

summary=""
if [[ "$(git -C "$root" cat-file -t "refs/tags/$tag" 2>/dev/null)" == "tag" ]]; then
  summary="$(git -C "$root" tag -l --format='%(contents:subject)' "$tag")"
fi
summary="${summary:-Ebb $version}"

SUMMARY="$summary" VERSION="$version" perl -pe \
  's/\{\{SUMMARY\}\}/$ENV{SUMMARY}/g; s/\{\{VERSION\}\}/$ENV{VERSION}/g' \
  "$root/.github/release-notes.md"
