import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gsettings/gsettings.dart';
import 'package:linuxpowertoys/src/backend_api/gnome/gnome_keybindings.dart';

import '../../utility_backend.dart';

class RunBackend extends UtilityBackend with ChangeNotifier {
  RunBackend()
      : settings = GSettings(
          "org.gnome.shell.extensions.linux-powertoys-run",
          schemaDirs: [
            '${Platform.environment["HOME"]}/.local/share/gnome-shell/extensions/LinuxPowerToys.Run@github.com/schemas/'
          ],
        );

  final GSettings settings;
  final GSettings gnomeSettings = GSettings('org.gnome.shell');

  bool _enabled = false;
  bool get enabled => _enabled;
  set enabled(bool enabled) {
    enable(enabled);
  }

  bool _installed = false;
  bool get installed => _installed;

  List<LogicalKeyboardKey> _summonKeybinding = [];
  List<LogicalKeyboardKey> get summonKeybinding => _summonKeybinding;
  set summonKeybinding(List<LogicalKeyboardKey> binding) {
    String bindingStr = binding.map((key) => GnomeKeyboardKey.fromLogicalKey(key)).toList().toBindingString();
    settings.set('summon-keybinding', DBusArray.string([bindingStr]));
  }

  StreamSubscription? _gnomeSettingSubscription;
  StreamSubscription? _settingSubscription;

  Future<void> fetch() async {
    DBusValue summonKeybindingRaw;

    await isEnabled();

    try {
      summonKeybindingRaw = await settings.get('summon-keybinding');
    } on GSettingsSchemaNotInstalledException catch (_) {
      _installed = false;
      _enabled = false;
      return;
    }

    String summonKeybinding = summonKeybindingRaw.asStringArray().first;
    _summonKeybinding = GnomeKeyboardKey.parseBinding(summonKeybinding);

    _settingSubscription = settings.keysChanged.listen(_onRunSettingsChanged);
    _gnomeSettingSubscription = gnomeSettings.keysChanged.listen(_onGnomeSettingsChanged);
    notifyListeners();
  }

  void _onRunSettingsChanged(List<String> keys) async {
    if (keys.contains("summon-keybinding")) {
      DBusValue result = await settings.get('summon-keybinding');
      String summonKeybinding = "";

      if (result.signature == DBusSignature.string) {
        summonKeybinding = result.asString();
      } else if (result.signature == DBusSignature.array(DBusSignature.string)) {
        summonKeybinding = result.asStringArray().first;
      }

      _summonKeybinding = GnomeKeyboardKey.parseBinding(summonKeybinding);
    }

    notifyListeners();
  }

  void _onGnomeSettingsChanged(List<String> keys) async {
    if (keys.contains("enabled-extensions")) {
      DBusValue result = await gnomeSettings.get('enabled-extensions');
      bool newValue = result.asStringArray().contains('LinuxPowerToys.Run@github.com');

      if (newValue != _enabled) {
        _enabled = newValue;
        notifyListeners();
      }
    }
  }

  @override
  Future<bool> enable(bool newValue) async {
    DBusValue result = await gnomeSettings.get('enabled-extensions');
    List<String> enabledExtensions = result.asStringArray().toList();

    if (newValue) {
      enabledExtensions.add("LinuxPowerToys.Run@github.com");
    } else {
      enabledExtensions.remove("LinuxPowerToys.Run@github.com");
    }

    gnomeSettings.set('enabled-extensions', DBusArray.string(enabledExtensions));

    return true;
  }

  @override
  Future<void> install() async {}

  @override
  Future<bool> isEnabled() async {
    DBusValue result = await gnomeSettings.get('enabled-extensions');
    _enabled = result.asStringArray().contains('LinuxPowerToys.Run@github.com');
    return _enabled;
  }

  @override
  Future<bool> isInstalled() async {
    return _installed;
  }

  @override
  Future<void> uninstall() async {}

  @override
  void dispose() {
    _gnomeSettingSubscription?.cancel();
    _settingSubscription?.cancel();

    settings.close();
    gnomeSettings.close();

    super.dispose();
  }
}
