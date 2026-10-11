# Ebb

开源、全平台的订阅管理器。Flutter 开发，数据只存本机，支持从 Tilla 和 SubscriptionManager 导入。

## 先读

| 文档 | 用途 |
| --- | --- |
| [PRD（Claude Docs）](https://claude.ai/code/artifact/c113f247-0ff6-45ea-9d34-b1eac620c9cd) | 需求的唯一来源：功能范围、已定决策、分类、同步方案。用 Claude Docs 工具读，不要网页抓取 |
| [设计规范与高保真稿（Design 画布）](https://claude.ai/artifact/9tMkfM9sBybhBHXCMu5F77) | 视觉与交互的唯一来源：色板、字号、组件、手机三页、桌面双栏、图标。用 Artifact 工具 `read` |
| `docs/import-formats.md` | 两个 App 导出格式的逆向结论，导入器照此实现 |
| `LOCAL.md` | 只在本机：真实导出文件位置等，不进 git |

PRD 或设计稿与本文件冲突时，以 PRD 和设计稿为准，并提醒用户更新本文件。

## 工作方式

- 先讨论、等用户确认再动手：新的模块、依赖、目录结构先给方案和推荐，一次一个决定。
- 代码按职责拆成小文件（单文件约 100 行以内），目录合理，不堆冗余文件和重复文档。
- 命名和分组追求表意，不追求形似：不凑字数对称，不套「X 与 Y」模板。
- 用中文交流。
- 用户的真实导出文件含住址、授权码、卡号尾号：只在本机冒烟测试时读取，绝不复制进仓库；测试用手写的假数据。

## 已定技术决策

| 项 | 决定 |
| --- | --- |
| 框架 | Flutter 3.47（brew cask 安装），Material 3 + 自定义主题，不用 Cupertino 自适应控件 |
| 存储 | SQLite + drift；第一版只存本机 |
| 状态管理 | Riverpod |
| 多语言 | 官方 gen-l10n，中文 / English，跟随系统 |
| 应用 ID | `com.unofn.ebb`（定了不能改） |
| 显示名 | Ebb；商店标题「Ebb — 订阅管理 / Subscription Tracker」 |
| 协议 | GPL-3.0 |
| 最低系统 | Android 10、iOS 16、macOS 13、Windows 10、Ubuntu 22.04；不为更旧系统做兼容 |
| 发布 | GitHub Releases 自动构建（Android APK、macOS、Windows、Linux）；暂无 iOS 发布（没有开发者账号） |
| 签名 | Android 密钥本地生成，本机放一份（`android/key.properties` + keystore，均不进 git），GitHub Secrets 放一份 |
| 联网 | 零遥测、无崩溃上报；只连汇率接口（open.er-api.com，先实测国内可达性）和 GitHub Releases（新版本检查，可关） |
| 字体 | IBM Plex Sans（拉丁与等宽数字）+ Noto Sans SC，打包进 App |
| 图标 | 方向 C「退潮刻度」：三道由长到短的横线，最短一道为强调色 |

## 产品规则（容易做错）

- **首页大数字是「月均成本」**：年付 ÷ 12 等折算；统计页历史图表才是「实付」。
- **不计入月均**：试用中、到期不续、已退订、标记为报销的订阅。
- **合租**只算「我的份额」；**首期优惠**按恢复后的原价算月均。
- **付款记录**单独一张表，每笔记下当时汇率；改价只影响以后的扣款。
- **多币种**：按原币录入和展示，多条汇总时折算为基准货币（默认 CNY，可设）。
- **分类**：按品类分（能互相替代的归一类），27 个品类 + 6 个统计分组，完整列表和边界规则见 PRD「默认分类」。交叉标记（AI、家庭共享）用标签。
- **为第二版同步预留**：所有表 UUID 主键；每条记录有更新时间（HLC）和软删除标记；本机存设备 ID；金额用整数最小单位 + 币种；汇率缓存等本机数据不参与同步；所有写入经统一数据层。
- **备份**是 zip（JSON 数据 + 附件），另可导出 CSV。

## 里程碑

| 里程碑 | 内容 | 完成标准 |
| --- | --- | --- |
| M1 数据与导入 | 数据模型、drift 表、计费周期计算、Tilla / SubscriptionManager 导入器、导入预览与去重、续订链识别 | 单元测试覆盖导入和周期计算；用 `LOCAL.md` 里的真实文件冒烟：Tilla 23 条、SubscriptionManager 59 条全部导入 |
| M2 列表、编辑、提醒 | 首页、详情、编辑表单、服务预设、本地通知、到期不续、试用、首期优惠、归档、批量编辑 | 手机与桌面布局按设计稿；通知在 Android、macOS 上实测 |
| M3 统计、预算、复盘 | 实付历史、未来 12 个月预测、分组与品类分析、同类重复提示、预算、季度复盘、汇率 | 统计页数字与首页、预算一致 |
| M4 打磨与发布 | 深色模式细调、动效、空状态、备份恢复、新版本检查、CI 发布 | GitHub Releases 产出四个平台安装包 |

每个里程碑开始前，先和用户确认范围与目录结构。

## 第一次开工

1. 和用户确认 Flutter 工程结构（feature-first 目录、包选型）后再 `flutter create`。
2. `flutter create` 不要覆盖已有的 `AGENTS.md`、`docs/`、`.gitignore`；把它生成的忽略规则合并进现有 `.gitignore`。
3. `git init` 后第一次提交前，确认 `LOCAL.md`、真实导出文件、签名文件都被忽略。
