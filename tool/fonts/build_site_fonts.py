"""生成官网（site/）用的 woff2 字体，取自 assets/fonts/ 的 App 内置字体。

IBM Plex Sans 保留拉丁、标点和货币符号；Noto Sans SC 只保留 site/ 下网页实际
用到的字，改了中文文案要重新运行，否则新字退回系统字体。

用法（需要 fonttools 和 brotli）：
    python3 -m venv .venv && .venv/bin/pip install fonttools brotli
    .venv/bin/python tool/fonts/build_site_fonts.py
"""

from __future__ import annotations

import html
import re
from pathlib import Path

from fontTools import subset

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / "assets" / "fonts"
SITE = ROOT / "site"
OUT = SITE / "fonts"

# 基本拉丁、拉丁补充、通用标点、货币。
LATIN = [(0x0020, 0x007E), (0x00A0, 0x00FF), (0x2000, 0x206F), (0x20A0, 0x20CF)]


def page_text() -> str:
    """Visible text of every page, tags and scripts removed."""
    text = ""
    for page in SITE.rglob("*.html"):
        source = re.sub(r"<script.*?</script>", "", page.read_text(), flags=re.S)
        text += html.unescape(re.sub(r"<[^>]+>", "", source))
    return text


def build(source: str, out: str, unicodes: set[int]) -> None:
    options = subset.Options()
    options.flavor = "woff2"
    options.layout_features = ["*"]
    font = subset.load_font(str(FONTS / source), options)
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=unicodes)
    subsetter.subset(font)
    subset.save_font(font, str(OUT / out), options)
    print(f"{out}: {(OUT / out).stat().st_size // 1024} KB")


def main() -> None:
    OUT.mkdir(exist_ok=True)
    latin = {c for start, end in LATIN for c in range(start, end + 1)}
    chinese = {ord(c) for c in page_text() if ord(c) > 0x2E7F} | latin
    for weight, name in [(400, "Regular"), (600, "SemiBold")]:
        build(f"IBMPlexSans-{name}.ttf", f"ibm-plex-sans-{weight}.woff2", latin)
        build(f"NotoSansSC-{name}.ttf", f"noto-sans-sc-{weight}.woff2", chinese)


if __name__ == "__main__":
    main()
