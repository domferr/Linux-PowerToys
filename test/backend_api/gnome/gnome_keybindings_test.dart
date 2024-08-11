import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linuxpowertoys/src/backend_api/gnome/gnome_keybindings.dart';

void main() {
  test("creation", () {
    GnomeKeyboardKey key = GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.space);
    expect(key, GnomeKeyboardKey(LogicalKeyboardKey.space.keyId));

    key = GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.alt);
    expect(key, GnomeKeyboardKey(LogicalKeyboardKey.alt.keyId));

    key = GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.f1);
    expect(key, GnomeKeyboardKey(LogicalKeyboardKey.f1.keyId));
  });

  test("binding creation", () {
    List<GnomeKeyboardKey> keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.alt),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.space),
    ];
    expect(keys.toBindingString(), "<alt>Space");

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.altLeft),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.f1),
    ];
    expect(keys.toBindingString(), "<alt>F1");

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.altRight),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.home),
    ];
    expect(keys.toBindingString(), "<alt>Home");

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.meta),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.insert),
    ];
    expect(keys.toBindingString(), "<meta>Insert");

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.metaLeft),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.delete),
    ];
    expect(keys.toBindingString(), "<meta>Delete");

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.metaRight),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.end),
    ];
    expect(keys.toBindingString(), "<meta>End");

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.shift),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.control),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.keyN),
    ];
    expect(keys.toBindingString(), "<shift><control>N");

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.shiftLeft),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.controlLeft),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.keyN),
    ];
    expect(keys.toBindingString(), "<shift><control>N");

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.shiftRight),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.controlRight),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.keyN),
    ];
    expect(keys.toBindingString(), "<shift><control>N");
  });

  test("binding parsing", () {
    List<GnomeKeyboardKey> keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.alt),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.space),
    ];
    expect(keys, GnomeKeyboardKey.parseBinding("<alt>Space"));

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.alt),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.f1),
    ];
    expect(keys, GnomeKeyboardKey.parseBinding("<alt>F1"));

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.alt),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.home),
    ];
    expect(keys, GnomeKeyboardKey.parseBinding("<alt>Home"));

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.meta),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.insert),
    ];
    expect(keys, GnomeKeyboardKey.parseBinding("<meta>Insert"));

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.meta),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.delete),
    ];
    expect(keys, GnomeKeyboardKey.parseBinding("<meta>Delete"));

    keys = [
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.shift),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.control),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.meta),
      GnomeKeyboardKey.fromLogicalKey(LogicalKeyboardKey.end),
    ];
    expect(keys, GnomeKeyboardKey.parseBinding("<shift><control><meta>End"));
  });
}
