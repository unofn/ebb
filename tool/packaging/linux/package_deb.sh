#!/usr/bin/env bash
# 把 `flutter build linux --release` 的 bundle 打成 .deb：
#   /opt/ebb/               程序本体
#   /usr/bin/ebb            指向 /opt/ebb/ebb 的软链接
#   /usr/share/applications/com.unofn.ebb.desktop
#   /usr/share/icons/hicolor/<尺寸>/apps/com.unofn.ebb.png
# 文件名和图标名都用应用 ID，和窗口的 application id 对上，GNOME 才能认出图标。
#   tool/packaging/linux/package_deb.sh <版本>   → build/dist/ebb-<版本>-linux-amd64.deb
set -euo pipefail

version="$1"
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
bundle="$root/build/linux/x64/release/bundle"
packaging="$root/linux/packaging"
dist="$root/build/dist"
out="$dist/ebb-$version-linux-amd64.deb"
app_id="com.unofn.ebb"

[[ -x "$bundle/ebb" ]] || { echo "找不到 $bundle/ebb，先运行 flutter build linux --release" >&2; exit 1; }
# Flutter 引擎经 libepoxy 用 dlopen 加载 EGL 和 GLES，readelf 看不到，单独补上。
depends="$("$here/depends.sh" "$bundle"), libegl1, libgles2"

pkg="$(mktemp -d)"
trap 'rm -rf "$pkg"' EXIT
mkdir -p "$pkg/opt/ebb" "$pkg/usr/bin" "$pkg/usr/share/applications" "$pkg/DEBIAN"
cp -a "$bundle/." "$pkg/opt/ebb/"
ln -s /opt/ebb/ebb "$pkg/usr/bin/ebb"
install -m 644 "$packaging/$app_id.desktop" "$pkg/usr/share/applications/"
cp -a "$packaging/icons" "$pkg/usr/share/"
chmod -R u=rwX,go=rX "$pkg"

cat >"$pkg/DEBIAN/control" <<CONTROL
Package: ebb
Version: $version
Architecture: amd64
Maintainer: unofn
Installed-Size: $(du -sk --exclude=DEBIAN "$pkg" | cut -f1)
Depends: $depends
Recommends: xdg-desktop-portal, xdg-utils
Section: utils
Priority: optional
Homepage: https://github.com/unofn/ebb
Description: Open-source subscription tracker
 Ebb tracks your subscriptions, shows what they cost per month and reminds
 you before each renewal. All data stays on your device.
CONTROL

mkdir -p "$dist"
dpkg-deb --root-owner-group --build "$pkg" "$out" >/dev/null
echo "Depends: $depends"
echo "$out"
