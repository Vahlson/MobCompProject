// Place fonts/customIcons.ttf in your fonts/ directory and
// add the following to your pubspec.yaml
// flutter:
//   fonts:
//    - family: customIcons
//      fonts:
//       - asset: fonts/customIcons.ttf
import 'package:flutter/widgets.dart';

class CustomIcons {
  CustomIcons._();

  static const String _fontFamily = 'customIcons';

  static const IconData eraser = IconData(0xe903, fontFamily: _fontFamily);
  static const IconData humidity_mid = IconData(0xe902, fontFamily: _fontFamily);
  static const IconData humidity_low = IconData(0xe900, fontFamily: _fontFamily);
  static const IconData humidity_high = IconData(0xe901, fontFamily: _fontFamily);
}
