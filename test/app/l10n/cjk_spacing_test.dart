import 'package:ebb/app/l10n/app_localizations.dart';
import 'package:ebb/app/l10n/cjk_spacing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pads only a Latin letter or digit at that end', () {
    expect(padEnd('多邻国 Super'), '多邻国 Super ');
    expect(padEnd('iCloud+ 200GB'), 'iCloud+ 200GB ');
    expect(padEnd('Keep 会员'), 'Keep 会员');
    expect(padEnd('Café'), 'Café ', reason: 'Latin with accents');
    expect(padEnd('iCloud+'), 'iCloud+', reason: 'ends with a symbol');
    expect(padEnd(''), '');
    expect(padStart('AI 助手'), ' AI 助手');
    expect(padStart('视频'), '视频');
    expect(padStart('1Password'), ' 1Password');
  });

  test('spaces Chinese templates and leaves English as is', () {
    final zh = lookupAppLocalizations(const Locale('zh'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(zh.duplicateTitle(2, zh.amidHan('AI 助手')), '你有 2 个 AI 助手订阅');
    expect(zh.duplicateTitle(2, zh.amidHan('视频')), '你有 2 个视频订阅');
    expect(
      zh.homeTrialHint(zh.beforeHan('多邻国 Super'), 6),
      '多邻国 Super 试用 6 天后到期',
    );
    expect(zh.homeTrialHint(zh.beforeHan('Keep 会员'), 6), 'Keep 会员试用 6 天后到期');
    expect(
      zh.reviewFlowDuplicate(zh.beforeHan('VPN'), zh.afterHan('Surfshark'), 1),
      'VPN 还有 Surfshark，两个都在用吗？',
    );
    expect(
      en.duplicateTitle(2, en.amidHan('AI assistants')),
      '2 AI assistants subscriptions',
    );
    expect(
      en.homeTrialHint(en.beforeHan('Super Duolingo'), 6),
      'Super Duolingo trial ends in 6 days',
    );
  });
}
