import 'package:flutter/widgets.dart';

/// The few animations: changed figures fade in, bars and hint cards
/// settle; none at all when the system turns animations off.
abstract final class Motion {
  /// A figure fading to its new value.
  static const fade = Duration(milliseconds: 200);

  /// A bar or card reaching its new size or color.
  static const settle = Duration(milliseconds: 300);

  static const curve = Curves.easeOutCubic;
}

extension MotionOf on BuildContext {
  /// [duration], or zero when the system turns animations off.
  Duration motion(Duration duration) =>
      MediaQuery.disableAnimationsOf(this) ? Duration.zero : duration;
}
