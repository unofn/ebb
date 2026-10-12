import '../../data/database.dart';
import 'app_localizations.dart';

// 内置品类只存键，名称按语言从这里取；键见 data/seed/categories.dart。

/// The localized name of the built-in category [key].
String categoryName(AppLocalizations l10n, String key) => switch (key) {
  'video' => l10n.categoryVideo,
  'audio' => l10n.categoryAudio,
  'gaming' => l10n.categoryGaming,
  'social' => l10n.categorySocial,
  'reading' => l10n.categoryReading,
  'courses' => l10n.categoryCourses,
  'communities' => l10n.categoryCommunities,
  'ai_assistant' => l10n.categoryAiAssistant,
  'productivity' => l10n.categoryProductivity,
  'creative' => l10n.categoryCreative,
  'developer' => l10n.categoryDeveloper,
  'cloud' => l10n.categoryCloud,
  'storage' => l10n.categoryStorage,
  'vpn' => l10n.categoryVpn,
  'security' => l10n.categorySecurity,
  'other_software' => l10n.categoryOtherSoftware,
  'shopping' => l10n.categoryShopping,
  'food' => l10n.categoryFood,
  'transport' => l10n.categoryTransport,
  'health' => l10n.categoryHealth,
  'housing' => l10n.categoryHousing,
  'utilities' => l10n.categoryUtilities,
  'telecom' => l10n.categoryTelecom,
  'insurance' => l10n.categoryInsurance,
  'bank_fees' => l10n.categoryBankFees,
  'donation' => l10n.categoryDonation,
  'other' => l10n.categoryOther,
  _ => key,
};

/// The localized name of the statistics group [key].
String categoryGroupName(AppLocalizations l10n, String key) => switch (key) {
  'entertainment' => l10n.groupEntertainment,
  'learning' => l10n.groupLearning,
  'software' => l10n.groupSoftware,
  'life' => l10n.groupLife,
  'finance' => l10n.groupFinance,
  'other' => l10n.groupOther,
  _ => key,
};

/// [category]'s name as shown: the user's name for it, else the built-in
/// one in the current language.
String categoryLabel(AppLocalizations l10n, Category category) =>
    category.name ?? categoryName(l10n, category.key ?? '');
