"""由 assets/presets/services.json 生成 lib/features/presets/preset_icons.dart。

只列预设用到的 Simple Icons 图标，发布构建会裁掉其余字形。改了 services.json 里的
icon 之后重跑；测试会核对两边一致。只用标准库，需先 `flutter pub get`。

用法：
    python3 tool/presets/gen_preset_icons.py
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import url2pathname

ROOT = Path(__file__).resolve().parents[2]
SERVICES = ROOT / 'assets/presets/services.json'
OUTPUT = ROOT / 'lib/features/presets/preset_icons.dart'


def simple_icons_names() -> set[str]:
    """Identifiers declared by the resolved simple_icons package."""
    config = json.loads((ROOT / '.dart_tool/package_config.json').read_text())
    package = next(p for p in config['packages'] if p['name'] == 'simple_icons')
    root = Path(url2pathname(urlparse(package['rootUri']).path))
    source = (root / 'lib/src/icon_data.g.dart').read_text()
    return set(re.findall(r'static const IconData (\w+) =', source))


def dart_name(slug: str) -> str:
    """Simple Icons slug → Dart identifier (`1password` → `n1password`)."""
    return f'n{slug}' if slug[0].isdigit() else slug


def main() -> None:
    presets = json.loads(SERVICES.read_text())
    slugs = sorted({p['icon'] for p in presets if p.get('icon')})
    names = simple_icons_names()
    missing = [s for s in slugs if dart_name(s) not in names]
    if missing:
        raise SystemExit(f'Not in simple_icons: {", ".join(missing)}')

    lines = [
        "import 'package:flutter/widgets.dart';",
        "import 'package:simple_icons/simple_icons.dart';",
        '',
        '// 由 tool/presets/gen_preset_icons.py 生成，勿手改。',
        '',
        '/// Simple Icons slug → glyph, for the slugs `services.json` uses.',
        'const presetIcons = <String, IconData>{',
        *(f"  '{s}': SimpleIcons.{dart_name(s)}," for s in slugs),
        '};',
    ]
    OUTPUT.write_text('\n'.join(lines) + '\n')
    print(f'{len(slugs)} icons → {OUTPUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
