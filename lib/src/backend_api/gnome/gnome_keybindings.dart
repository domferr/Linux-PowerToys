import 'package:flutter/services.dart';

/// keyboard key in the gnome format
class GnomeKeyboardKey extends LogicalKeyboardKey {
  const GnomeKeyboardKey(super.keyId);

  /// convert a [LogicalKeyboardKey] into a [GnomeKeyboardKey]
  GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey key) : super(key.keyId);

  @override
  String get keyLabel => switch (LogicalKeyboardKey(keyId)) {
        LogicalKeyboardKey.control => "<control>",
        LogicalKeyboardKey.controlLeft => "<control>",
        LogicalKeyboardKey.controlRight => "<control>",
        LogicalKeyboardKey.alt => "<alt>",
        LogicalKeyboardKey.altLeft => "<alt>",
        LogicalKeyboardKey.altRight => "<alt>",
        LogicalKeyboardKey.shift => "<shift>",
        LogicalKeyboardKey.shiftLeft => "<shift>",
        LogicalKeyboardKey.shiftRight => "<shift>",
        LogicalKeyboardKey.meta => "<meta>",
        LogicalKeyboardKey.metaLeft => "<meta>",
        LogicalKeyboardKey.metaRight => "<meta>",
        LogicalKeyboardKey.space => "Space",
        _ => super.keyLabel,
      };

  static final RegExp _fKeysName = RegExp(r'f[0-9]{1,2}');

  static final Map<String, GnomeKeyboardKey> _parseTable = {
    "<meta>": GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.meta),
    "<shift>": GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.shift),
    "<control>": GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.control),
    "<alt>": GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.alt),
    "space": GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.space),
    "home": GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.home),
    "insert": GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.insert),
    "delete": GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.delete),
    "end": GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.end),
  };

  /// parse a gnome keybinding
  static List<GnomeKeyboardKey> parseBinding(String text) {
    List<GnomeKeyboardKey> keys = [];

    text = text.trim().replaceAll(" ", "").toLowerCase();

    while (text.isNotEmpty) {
      GnomeKeyboardKey? key;

      for (String keyStr in _parseTable.keys) {
        if (text.indexOf(keyStr) == 0) {
          key = _parseTable[keyStr];
          text = text.substring(keyStr.length - 1);
          break;
        }
      }

      Match? fKeyMatch = _fKeysName.firstMatch(text);
      if (fKeyMatch != null && fKeyMatch.start == 0) {
        int fNumber = int.parse(text.substring(1, fKeyMatch.end));

        text = text.substring(fKeyMatch.end - 1);
        key = GnomeKeyboardKey(0x00100000800 + fNumber);
      }

      key ??= GnomeKeyboardKey(text[0].runes.first);
      text = text.substring(1);

      keys.add(key);
    }

    return keys;
  }
}

/// extension for generating gnome keybinding strings
extension KeyGnomeBinding on List<GnomeKeyboardKey> {
  /// generate gnome keybinding string
  String toBindingString() {
    String result = "";
    for (GnomeKeyboardKey key in this) {
      result += key.keyLabel;
    }

    return result;
  }
}
