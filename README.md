# Ebb

An open-source subscription tracker for Android, macOS, Windows and Linux. Your data stays on your device.

[中文](#中文)

## Features

- **What you really pay each month.** Yearly and other plans are averaged into a monthly cost. Shared plans count only your share. Intro prices count at the regular price they return to.
- **Any currency.** Enter each subscription in its own currency; totals are converted to your base currency at the latest exchange rates.
- **Reminders** before each charge, plus trials, plans you won't renew, and an archive for cancelled ones.
- **Stats**: what you actually paid, a 12-month forecast, spending by group and category, overlapping services, a monthly budget and a quarterly review.
- **Import** from Tilla and SubscriptionManager.
- **Backups** as a single zip file you keep, CSV export, and receipts attached to subscriptions.
- English and Chinese, light and dark themes.

## Privacy

Everything is stored on your device. There is no account, no telemetry and no crash reporting. Ebb connects to only two places:

- [open.er-api.com](https://open.er-api.com) for exchange rates
- GitHub Releases, to check for a new version (you can turn this off in Settings)

## Download

Get the latest version from [Releases](https://github.com/unofn/ebb/releases/latest). The release notes explain how to open the app the first time, since the installers are not signed by Apple or Microsoft.

Supported systems: Android 10+, macOS 13+, Windows 10+, Ubuntu 22.04+. iOS isn't available yet.

## Build from source

With Flutter 3.47:

```sh
flutter pub get
dart run build_runner build
flutter run
```

Development notes (in Chinese) are in [AGENTS.md](AGENTS.md).

## License

[GPL-3.0](LICENSE)

---

## 中文

开源的订阅管理器，支持 Android、macOS、Windows 和 Linux。数据只存本机。

### 功能

- **每月真正花多少**：年付等按月折算成月均成本；合租只算你的份额；首期优惠按恢复后的原价算。
- **多币种**：每个订阅按原币录入，汇总时按最新汇率折算成你的基准货币。
- **扣费前提醒**，以及试用、到期不续，退订的订阅可以归档。
- **统计**：实付历史、未来 12 个月预测、按分组和品类分析、同类重复提示、月度预算、季度复盘。
- **导入**：支持 Tilla 和 SubscriptionManager 的导出文件。
- **备份**成一个 zip 文件自己保存，可导出 CSV，订阅可以附上发票收据。
- 中文和英文界面，浅色和深色主题。

### 隐私

所有数据都存在你的设备上：没有账号，没有遥测，也没有崩溃上报。Ebb 只连两个地方：

- [open.er-api.com](https://open.er-api.com)：获取汇率
- GitHub Releases：检查新版本（可在设置里关闭）

### 下载

到 [Releases](https://github.com/unofn/ebb/releases/latest) 下载最新版。安装包没有经过 Apple、Microsoft 的签名认证，第一次打开的方法见发布说明。

支持的系统：Android 10+、macOS 13+、Windows 10+、Ubuntu 22.04+。暂无 iOS 版。

### 从源码构建

需要 Flutter 3.47：

```sh
flutter pub get
dart run build_runner build
flutter run
```

开发说明见 [AGENTS.md](AGENTS.md)。

### 协议

[GPL-3.0](LICENSE)
