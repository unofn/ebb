#!/usr/bin/env bash
# 列出 bundle 运行时要的系统包，逗号分隔，写进 .deb 的 Depends。
#   tool/packaging/linux/depends.sh <bundle 目录>
# 只看 ebb 和 lib/*.so 直接链接的库（readelf 的 NEEDED），用 ldd 找到它们在
# 系统里的路径，再用 dpkg -S 查出所属的包；bundle 自带的库不算。
# 有库找不到就失败，免得打出缺依赖的包。
set -euo pipefail

bundle="$(cd "$1" && pwd)"
elfs=("$bundle/ebb" "$bundle"/lib/*.so)

needed="$(for elf in "${elfs[@]}"; do
  readelf -d "$elf" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p'
done | sort -u)"

paths="$(for elf in "${elfs[@]}"; do
  LD_LIBRARY_PATH="$bundle/lib" ldd "$elf"
done | sort -u)"

if grep -q 'not found' <<<"$paths"; then
  grep 'not found' <<<"$paths" >&2
  exit 1
fi

for soname in $needed; do
  [[ -e "$bundle/lib/$soname" ]] && continue
  [[ "$soname" == ld-linux* ]] && continue  # 动态链接器，属于 libc6
  path="$(awk -v so="$soname" '$1 == so && $2 == "=>" { print $3; exit }' <<<"$paths")"
  [[ -n "$path" ]] || { echo "ldd 里找不到 $soname" >&2; exit 1; }
  # usrmerge 系统上 ldd 给的是 /lib/...，dpkg 记的可能是 /usr/lib/...，两个都试。
  dpkg -S "$path" 2>/dev/null || dpkg -S "/usr$path" 2>/dev/null || dpkg -S "$(realpath "$path")"
done | cut -d: -f1 | sort -u | paste -sd, - | sed 's/,/, /g'
