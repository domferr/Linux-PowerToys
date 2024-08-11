import 'package:dbus/dbus.dart';
import 'package:gsettings/gsettings.dart';

import '../run_plugin_backend.dart';

class RunGitSettingsBackend extends RunPluginSettings {
  RunGitSettingsBackend(super.settings);

  factory RunGitSettingsBackend.fromInterface(String interface) => RunGitSettingsBackend(GSettings(interface));

  List<String> _basePaths = [];
  List<String> get basePaths => _basePaths;

  List<String> _ignorePaths = [];
  List<String> get ignorePaths => _ignorePaths;

  @override
  Future<void> fetchSettings() async {
    DBusValue searchPaths = await settings.get("search-paths");
    if (searchPaths.signature != DBusSignature.array(DBusSignature.string)) {
      throw const FormatException("'search-paths' must be of type string array");
    }
    _basePaths = searchPaths.asStringArray().toList();

    DBusValue ignorePaths = await settings.get("exclude-search-paths");
    if (ignorePaths.signature != DBusSignature.array(DBusSignature.string)) {
      throw const FormatException("'exclude-search-path' must be of type string array");
    }
    _ignorePaths = ignorePaths.asStringArray().toList();

    await super.fetchSettings();
  }

  Future<void> _updateSearchPaths() async {
    await settings.set("search-paths", DBusArray.string(_basePaths));
  }

  Future<void> modifySearchPaths(int index, String ignorePath) async {
    _basePaths[index] = ignorePath;
    await _updateSearchPaths();
  }

  Future<void> addSearchPaths(String ignorePath) async {
    _basePaths.add(ignorePath);
    await _updateSearchPaths();
  }

  Future<void> removeSearchPaths(String ignorePath) async {
    _basePaths.remove(ignorePath);
    await _updateSearchPaths();
  }

  Future<void> _updateIgnorePaths() async {
    await settings.set("exclude-search-paths", DBusArray.string(_ignorePaths));
  }

  Future<void> modifyIgnorePaths(int index, String ignorePath) async {
    _ignorePaths[index] = ignorePath;
    await _updateIgnorePaths();
  }

  Future<void> addIgnorePaths(String ignorePath) async {
    _ignorePaths.add(ignorePath);
    await _updateIgnorePaths();
  }

  Future<void> removeIgnorePaths(String ignorePath) async {
    _ignorePaths.remove(ignorePath);
    await _updateIgnorePaths();
  }

  @override
  void onChange(List<String> keys) async {
    if (keys.contains("search-paths")) {
      _basePaths = (await settings.get("search-paths")).asStringArray().toList();
    }

    if (keys.contains("exclude-search-paths")) {
      _ignorePaths = (await settings.get("exclude-search-paths")).asStringArray().toList();
    }

    super.onChange(keys);
  }
}
