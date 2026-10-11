// 以下枚举按名称存成 TEXT（drift textEnum）：只能追加，已有名称不能改。

enum SubscriptionKind { recurring, oneTime }

enum CycleUnit { day, week, month, year }

enum SubscriptionStatus { active, paused, ending, cancelled }

/// How a payment row came to exist.
enum PaymentOrigin { manual, auto, imported, backfilled }

enum AttachmentKind { icon, receipt }
