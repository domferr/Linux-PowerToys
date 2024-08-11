import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:gsettings/gsettings.dart';

import '../search/search_plugin.dart';

abstract class RunPlugin {
  RunPlugin({
    required this.name,
    required String activationPrefix,
    required this.settings,
  }) : _activationPrefix = activationPrefix;

  final GSettings settings;

  String _activationPrefix;
  bool _enable = false;

  /// name of the plugin
  final String name;

  /// activation Prefix used to force the search engine to search only in this plugin
  String get activationPrefix => _activationPrefix;

  /// whether the plugin is enabled
  bool get enable => _enable;

  /// this function gets called when the application starts and the plugin is enabled
  /// fetches search entries, when they are to expensive to build
  Future<void> fetch();

  /// searches for a search entry in a plugin
  Stream<SearchEntry> find(String needle);

  /// setup the plug-in according to the gsettings
  Future<void> loadSettings() async {
    DBusValue rawEnabled = await settings.get("enabled");

    if (rawEnabled.signature != DBusSignature.boolean) throw const FormatException("enabled should be type of bool");
    _enable = rawEnabled.asBoolean();

    DBusValue? activationPrefix = await settings.get("activation-prefix");

    if (activationPrefix.signature != DBusSignature.string) {
      throw const FormatException("activation-prefix should be type of string");
    }
    _activationPrefix = activationPrefix.asString();

    settings.keysChanged.listen(_onChange);
  }

  void _onChange(List<String> keys) async {
    if (keys.contains("enabled")) {
      _enable = (await settings.get("enabled")).asBoolean();
    }

    if (keys.contains("activation-prefix")) {
      _activationPrefix = (await settings.get("activation-prefix")).asString();
    }
  }
}
