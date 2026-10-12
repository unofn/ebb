import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_choice.freezed.dart';

/// What a source category or label maps to in the import preview. Both
/// [Undecided] and [NoCategory] leave subscriptions without a category;
/// only [Undecided] still asks for a choice.
@freezed
sealed class CategoryChoice with _$CategoryChoice {
  /// Not chosen yet.
  const factory CategoryChoice.undecided() = Undecided;

  /// Chosen not to map to any category.
  const factory CategoryChoice.none() = NoCategory;

  /// Maps to the built-in category [key].
  const factory CategoryChoice.category(String key) = MapsToCategory;

  const CategoryChoice._();

  /// The category key, or null when there is none to use.
  String? get key => switch (this) {
    MapsToCategory(:final key) => key,
    _ => null,
  };
}
