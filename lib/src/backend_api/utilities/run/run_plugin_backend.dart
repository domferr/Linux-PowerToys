import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:gsettings/gsettings.dart';

/// handles the activation-prefix and enable state of each plugin
abstract class RunPluginSettings extends ChangeNotifier {
  RunPluginSettings(this.settings);

  /// settings of the plugin
  GSettings settings;

  StreamSubscription? _onChangeSubscription;

  String? _error;

  /// null if the plugin has currently no errors otherwise contains error text
  String? get error => _error;

  bool? _enable;

  /// whether the plugin is enabled
  ///
  /// if null the plugin settings has not been loaded jet
  bool? get enable => _enable;

  /// changes the enabled state of the plugin and notifies all listeners
  set enable(bool? enable) {
    assert(_error == null);
    assert(enable != null);

    settings.set("enabled", DBusBoolean(enable!));
    _enable = enable;
    notifyListeners();
  }

  String _activationPrefix = "";

  /// the activation-prefix of the plugin and
  String get activationPrefix => _activationPrefix;

  /// changes the activation-prefix of the plugin and notifies all listeners
  set activationPrefix(String activationPrefix) {
    assert(_error == null);
    assert(enable != null);

    settings.set("activation-prefix", DBusString(activationPrefix));
    _activationPrefix = activationPrefix;
    notifyListeners();
  }

  /// load the plugin settings from [GSettings] must be called before any other method executed or property is set
  Future<void> fetchSettings() async {
    DBusValue rawEnabled = await settings.get("enabled");

    if (rawEnabled.signature != DBusSignature.boolean) throw const FormatException("enabled should be type of bool");
    _enable = rawEnabled.asBoolean();

    DBusValue? activationPrefix = await settings.get("activation-prefix");

    if (activationPrefix.signature != DBusSignature.string) {
      throw const FormatException("activation-prefix should be type of string");
    }
    _activationPrefix = activationPrefix.asString();

    _error = null;
    _onChangeSubscription = settings.keysChanged.listen(onChange);
    notifyListeners();
  }

  /// does the same as [fetchSettings] but in a save way if an exception occurs
  /// the error property of the plugin gets set
  Future<void> fetchSettingsSave() async {
    try {
      await fetchSettings();
    } catch (e) {
      _enable = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// callback for external setting changes
  void onChange(List<String> keys) async {
    if (keys.contains("enabled")) {
      _enable = (await settings.get("enabled")).asBoolean();
    }

    if (keys.contains("activation-prefix")) {
      _activationPrefix = (await settings.get("activation-prefix")).asString();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _onChangeSubscription?.cancel();
    settings.close();
    super.dispose();
  }
}
