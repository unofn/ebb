{{SUMMARY}}

## Install

| Platform | File |
| --- | --- |
| Android 10+ | `ebb-{{VERSION}}-android.apk` |
| macOS 13+ (Intel and Apple silicon) | `ebb-{{VERSION}}-macos.dmg` |
| Windows 10+ | `ebb-{{VERSION}}-windows-setup.exe`, portable `ebb-{{VERSION}}-windows.zip` |
| Ubuntu 22.04+ / Debian-based | `ebb-{{VERSION}}-linux-amd64.deb`, portable `ebb-{{VERSION}}-linux-x64.tar.gz` |

The installers are not signed or notarized by Apple or Microsoft, so the system warns you the first time. Allow it once:

- **Android**: open the downloaded APK and allow "Install unknown apps" when asked.
- **macOS**: open the dmg and drag Ebb into Applications. On first launch the system says it can't verify the developer:
  - macOS 13 and 14: Control-click (or right-click) Ebb in Applications, choose Open, then Open again.
  - macOS 15 and later: double-click Ebb once and dismiss the warning, then go to System Settings → Privacy & Security, click "Open Anyway" near the bottom and confirm with your password.
- **Windows**: if "Windows protected your PC" appears, click "More info", then "Run anyway". For the portable version, unzip it and run `Ebb\ebb.exe`.
- **Linux**: `sudo apt install ./ebb-{{VERSION}}-linux-amd64.deb`; for the portable version, extract it and run `ebb/ebb`.

## 安装

| 平台 | 文件 |
| --- | --- |
| Android 10+ | `ebb-{{VERSION}}-android.apk` |
| macOS 13+（Intel 与 Apple 芯片） | `ebb-{{VERSION}}-macos.dmg` |
| Windows 10+ | `ebb-{{VERSION}}-windows-setup.exe`，免安装版 `ebb-{{VERSION}}-windows.zip` |
| Ubuntu 22.04+ / Debian 系 | `ebb-{{VERSION}}-linux-amd64.deb`，免安装版 `ebb-{{VERSION}}-linux-x64.tar.gz` |

安装包没有经过 Apple、Microsoft 的签名认证，第一次打开时系统会提示，按下面的步骤放行一次即可。

- **Android**：下载 APK 后打开，按提示允许「安装未知应用」。
- **macOS**：打开 dmg，把 Ebb 拖进「应用程序」。第一次打开时提示「无法验证开发者」：
  - macOS 13、14：在「应用程序」里按住 Control 点 Ebb（或右键），选「打开」，再点「打开」。
  - macOS 15 及以上：先双击一次 Ebb，关掉提示；到「系统设置 → 隐私与安全性」，在底部点「仍要打开」，输入密码确认。
- **Windows**：运行安装程序时如果出现「Windows 已保护你的电脑」，点「更多信息」，再点「仍要运行」。免安装版解压后运行 `Ebb\ebb.exe`。
- **Linux**：`sudo apt install ./ebb-{{VERSION}}-linux-amd64.deb`；免安装版解压后运行 `ebb/ebb`。
