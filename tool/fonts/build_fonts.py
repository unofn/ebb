"""生成 App 内置字体：IBM Plex Sans 与 Noto Sans SC 的 400 / 600 两个字重。

Noto Sans SC 只保留《通用规范汉字表》8105 字和常用符号，表外字退回系统字体。
源文件取自 google/fonts 的固定提交，结果写入 assets/fonts/。

用法（需要 fonttools）：
    python3 -m venv .venv && .venv/bin/pip install fonttools
    .venv/bin/python tool/fonts/build_fonts.py
"""

from __future__ import annotations

import io
import urllib.request
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

GOOGLE_FONTS = "https://raw.githubusercontent.com/google/fonts/bd8f81ddb5c74d5c8897b36ad88b440266245103/ofl"
SOURCES = {
    "IBMPlexSans": f"{GOOGLE_FONTS}/ibmplexsans/IBMPlexSans%5Bwdth,wght%5D.ttf",
    "NotoSansSC": f"{GOOGLE_FONTS}/notosanssc/NotoSansSC%5Bwght%5D.ttf",
}
WEIGHTS = {"Regular": 400, "SemiBold": 600}

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "fonts"
HANZI = ROOT / "tool" / "fonts" / "tongyong-8105.txt"

# 拉丁、通用标点、货币、字母类符号、箭头、CJK 标点、全角字符。
SYMBOL_RANGES = [
    (0x0020, 0x007E), (0x00A0, 0x00FF), (0x2000, 0x206F), (0x20A0, 0x20CF),
    (0x2100, 0x214F), (0x2190, 0x21FF), (0x3000, 0x303F), (0xFF00, 0xFFEF),
]


def download(url: str) -> TTFont:
    with urllib.request.urlopen(url) as response:
        return TTFont(io.BytesIO(response.read()))


def noto_codepoints() -> set[int]:
    hanzi = {ord(c) for c in HANZI.read_text(encoding="utf-8") if not c.isspace()}
    assert len(hanzi) == 8105, f"expected 8105 characters, got {len(hanzi)}"
    symbols = {cp for lo, hi in SYMBOL_RANGES for cp in range(lo, hi + 1)}
    return hanzi | symbols


def instance(font: TTFont, weight: int) -> TTFont:
    axes = {"wght": weight}
    if "wdth" in [a.axisTag for a in font["fvar"].axes]:
        axes["wdth"] = 100
    return instancer.instantiateVariableFont(font, axes, updateFontNames=True)


def keep(font: TTFont, codepoints: set[int] | None) -> None:
    options = subset.Options()
    options.layout_features = ["*"]  # 保留 tnum 等特性，金额要用等宽数字
    options.name_IDs = ["*"]
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    if codepoints is None:
        codepoints = set(font.getBestCmap())
    subsetter.populate(unicodes=codepoints)
    subsetter.subset(font)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for family, url in SOURCES.items():
        source = download(url)
        codepoints = noto_codepoints() if family == "NotoSansSC" else None
        for style, weight in WEIGHTS.items():
            font = instance(TTFont(io.BytesIO(_bytes(source))), weight)
            keep(font, codepoints)
            path = OUT / f"{family}-{style}.ttf"
            font.save(path)
            print(f"{path.relative_to(ROOT)}: {path.stat().st_size / 1e6:.2f} MB")


def _bytes(font: TTFont) -> bytes:
    buffer = io.BytesIO()
    font.save(buffer)
    return buffer.getvalue()


if __name__ == "__main__":
    main()
