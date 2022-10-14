// Place fonts/opacityIcons.ttf in your fonts/ directory and
// add the following to your pubspec.yaml
// flutter:
//   fonts:
//    - family: opacityIcons
//      fonts:
//       - asset: fonts/opacityIcons.ttf
import 'package:flutter/widgets.dart';

class OpacityIcons {
  OpacityIcons._();

  static const String _fontFamily = 'opacityIcons';

  static const IconData humidity_mid = IconData(0xe902, fontFamily: _fontFamily);
  static const IconData humidity_low = IconData(0xe900, fontFamily: _fontFamily);
  static const IconData humidity_high = IconData(0xe901, fontFamily: _fontFamily);
}
