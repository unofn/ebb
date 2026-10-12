#!/usr/bin/env bash
# 从 assets/icon/*.svg 生成各平台的应用图标。
#
# 用法（在仓库根目录或任意位置）：
#   tool/icons/build_icons.sh
#
# 步骤：
#   1. 用 headless Chrome 把每个 SVG 渲染成 assets/icon/ 下同名的 1024 PNG；
#   2. 把 ebb-desktop.svg 渲染成 Linux hicolor 各尺寸，放进 linux/packaging/icons/；
#   3. 运行 `dart run icons_launcher:create`，按 pubspec.yaml 里的
#      icons_launcher 配置生成 Android、iOS、macOS、Windows 的图标资源。
#
# 需要一个 Chrome：设了 CHROME 环境变量就用它，否则依次找 Playwright 的
# chrome-headless-shell 和 /Applications/Google Chrome.app。
# 生成的 PNG 和各平台资源文件都要进 git。
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
src="$root/assets/icon"
hicolor="$root/linux/packaging/icons/hicolor"
app_id="com.unofn.ebb"
linux_sizes=(16 24 32 48 64 128 256 512)

find_chrome() {
  if [[ -n "${CHROME:-}" ]]; then echo "$CHROME"; return; fi
  local shell
  shell="$(ls -d "$HOME"/Library/Caches/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell \
    "$HOME"/.cache/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell 2>/dev/null | tail -1 || true)"
  if [[ -n "$shell" ]]; then echo "$shell"; return; fi
  local app="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  if [[ -x "$app" ]]; then echo "$app"; return; fi
  echo "找不到 Chrome，请设置 CHROME=<chrome 可执行文件路径>" >&2
  exit 1
}

chrome="$(find_chrome)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# render <svg> <边长> <输出 png>：底色透明，按 1 倍像素截图。
render() {
  local svg="$1" size="$2" out="$3"
  cp "$svg" "$work/icon.svg"
  cat >"$work/icon.html" <<'HTML'
<!doctype html><html><head><style>
html,body{margin:0;background:transparent}
img{display:block;width:100vw;height:100vh}
</style></head><body><img src="icon.svg"></body></html>
HTML
  mkdir -p "$(dirname "$out")"
  "$chrome" --headless --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=1 --default-background-color=00000000 \
    --window-size="$size,$size" --screenshot="$out" \
    "file://$work/icon.html" >/dev/null 2>&1
  [[ -s "$out" ]] || { echo "渲染失败：$svg" >&2; exit 1; }
}

for svg in "$src"/*.svg; do
  render "$svg" 1024 "${svg%.svg}.png"
  echo "assets/icon/$(basename "${svg%.svg}").png"
done

for size in "${linux_sizes[@]}"; do
  render "$src/ebb-desktop.svg" "$size" "$hicolor/${size}x${size}/apps/$app_id.png"
done
echo "linux/packaging/icons/hicolor/*/apps/$app_id.png"

cd "$root"
dart run icons_launcher:create
