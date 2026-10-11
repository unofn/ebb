# 导入格式

两个 App 都没有公开导出格式。以下结论来自真实导出文件（2026-10-11），导入器照此实现。遇到不认识的版本或字段：给警告，不拒绝导入。

## 通用

- 两个文件都是 **base64 编码的 UTF-8 JSON**，按 76 列换行。解码前先去掉所有空白；解码后按 UTF-8 解析（内容含中文）。
- 身份只认「来源 App + 原始 ID」，从不按名称：同一个 App 里同名记录很常见（每年续费新建一条）。重复导入同一文件 = 更新已有记录，不新增。
- 两个 App 之间的同名条目只在预览里标出，由用户决定跳过哪条，不自动合并。
- 测试数据一律手写假数据，覆盖下文列出的边界情况。

## Tilla（Android）

文件名 `backup_<毫秒时间戳>.txt`，整个文件是 base64。

```jsonc
{
  "date": 1791702343980, "fileName": "backup_….txt", "version": 4,
  "subscriptions": [ … ],
  "paymentMethods": [{ "uuid": "…", "title": "微信", "icon": "<base64 PNG>", "isCustomIcon": false }],
  "categories": [], "profiles": []
}
```

识别：有 `version`（数字）、`subscriptions` 数组和 `paymentMethods` 键。只验证过 `version: 4`。

| Tilla 字段 | 含义 / 处理 |
| --- | --- |
| `uuid` | 原始 ID |
| `title` | 名称（去首尾空格，样本里有带尾随空格的） |
| `price`、`currency` | 价格；币种 `RMB` 要转成 ISO 的 `CNY` |
| `billingCycle` | `<单位>_<N>`，如 `month_1`、`year_1`；按通用规则解析（day / week / month / year） |
| `isOneTime` | true 为一次性买断，忽略周期；此时 `billingDate == nextBillDate`，且带时分 |
| `billingDate` | 毫秒时间戳。实测是**本期**扣费日（随续费滚动），不是首次扣费日，所以更早的历史查不到 |
| `nextBillDate` | 下次扣费日，原样采用 |
| `endDate` | 结束日期，可空 |
| `isSuspended` | 暂停 |
| `paymentTracking` | `AUTO` = 自动续费，`MANUAL` = 手动 |
| `isReminderEnabled` + `reminderType` | 提醒；`ONE_DAY` 1 天、`THREE_DAYS` 3 天、`ONE_WEEK` 7 天，按「数字词_单位」通用解析 |
| `paymentMethodId` | 指向 `paymentMethods[].uuid`，取其 `title` |
| `categoryId` | 内置分类编号，**文件里没有名称**；`-1` = 无分类。导入预览里让用户把每个编号映射到 Ebb 的品类（下拉选），不要猜名称 |
| `color` | Android 有符号 ARGB 整数，`(c >>> 0)` 转无符号后取低 24 位；`-1`（纯白）是默认值，当作无颜色 |
| `icon` | base64 PNG，字符串里含 `\n`，去空白后用 |
| `link`、`notes` | 链接、备注 |
| `payments` | 付款记录数组，样本里为空；结构未知，非空时给警告 |
| `profileId`、`profiles` | 样本里为空，暂不导入 |
| `shouldBeTinted` | 图标着色开关，忽略 |

**日期坑**：时间戳是设备本地时区的午夜（样本为 UTC+8）。转日期必须按时区格式化，直接按 UTC 取日期会早一天。导入器从数据反推导出时区（周期订阅时间戳对一天取模的众数）；只能确定到「模 24 小时」，所以 ±12 附近有歧义，取人口多的一侧（+12/+13 而非 −12/−11，−10 而非 +14）。

**历史付款**：从 `billingDate` 到 `nextBillDate` 之间按周期补出历史付款，不晚于今天。因为 `billingDate` 是本期扣费日，实际每条通常只补出当期一笔。

## SubscriptionManager（simolation，Android）

文件名 `<日期>.subscriptions`。前面是几行说明文字，其中一行全是 `-`，**之后**才是 base64。不要写死跳过行数，按「全横线行」定位。

```jsonc
{
  "appVersion": 79, "date": "Oct 11, 2026 15:12:53",
  "subscriptions": [ … ],
  "notifications": [{ "subscriptionId": 2, "status": 1, "time": "12:00",
                      "cycle": { "cycleDuration": 1, "cycleRhythm": 6, "cycleType": 3 }, "content": "$t is $p due", "fullName": 2 }]
}
```

识别：有 `appVersion`（数字）和 `subscriptions` 数组。只验证过 `appVersion: 79`。

| 字段 | 含义 / 处理 |
| --- | --- |
| `id` | 原始 ID（整数） |
| `name` | 名称 |
| `description` | 套餐或副标题（如「黄金会员」「家庭版」），存为描述，**不要**和 `note` 拼在一起 |
| `note` | 备注 |
| `type` | `0` 周期订阅，`1` 一次性 |
| `active` | 是否生效；false = 已退订 |
| `price.amount`、`price.currencyCode` | 价格与币种（样本有 CNY、USD、RUB、INR） |
| `cycle.cycleDuration` + `cycle.cycleRhythm` | 每 N 个单位；`cycleRhythm` 是 `java.util.Calendar` 字段常量：1 年、2 月、3/4 周、5/6 天。样本订阅里只出现 1 和 2；其他值给警告 |
| `cycle.cycleType` | 订阅里恒为 1，通知里为 3；含义未确认，忽略 |
| `firstBillingDate` | `YYYY-MM-DD`；**可能缺失**（样本有周期订阅没有它） |
| `expiringDate` | 到期日，可空。周期订阅作为结束日期（不含：到期日当天那一期就是没续上的那次，不记付款）；一次性买断只有购买日（已和用户确认）：有 `firstBillingDate` 时到期日写进备注，只有到期日时把它当购买日并给警告 |
| `duration` | 样本恒为 `-1`，推测是付款次数（-1 = 无限），未找到文档；非 -1 时给警告 |
| `labels` | 标签数组，原样导入为标签；预览里可顺手映射到品类 |
| `paymentMethod` | 自由文本，同一方式有多种写法（`Alipay` / `支付宝`），原样保留 |
| `color` | `#RRGGBB` |
| `notifications[]` | 按 `subscriptionId` 匹配；`status: 1` 为开启；`cycleRhythm` 6 = 提前 N 天 |

下次扣费日不在文件里，由 `firstBillingDate` + 周期推算：从起始日按整周期推进，月末要夹紧（1 月 31 日 + 1 个月 = 2 月 28/29 日，+2 个月 = 3 月 31 日），不要逐次累加。

**停用订阅的历史付款**（已和用户确认）：

- SubscriptionManager 停用时不记日期，查不出续了几期。竞品（Wallos、Bobby 等）也不猜退订日期。
- 停用且没有结束日期的：只计首期一笔，并标记「结束日期未知」；用户之后补上结束日期，再按周期补齐中间的付款。
- 同名、前后相隔约一个周期的记录识别为「续订链」（用户习惯每次续费新建一条、关掉旧的），预览里建议合并成一个订阅，保留每次的价格。

## 必须覆盖的测试情形

- Tilla：周期订阅；一次性买断（带时分）；`color: -1`；暂停；`categoryId: -1`；未知 `billingCycle`。
- SubscriptionManager：带说明文字头；多月周期（每 6 个月）；一次性且无任何日期；一次性带 `expiringDate`、无支付方式；周期订阅缺 `firstBillingDate`；未知 `cycleRhythm`；带提醒。
- 合并：同文件重复导入不新增；跨 App 同名只标记；续订链识别。
