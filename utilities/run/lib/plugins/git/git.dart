import 'dart:io';
import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart';
import 'package:gsettings/gsettings.dart';

import '../../plugins/plugins.dart';
import '../../resources/my_flutter_app_icons.dart';
import '../../search/search_plugin.dart';

extension GlobList on Iterable<Glob> {
  bool matchAny(String path) {
    for (Glob glob in this) {
      if (glob.matches(path)) return true;
    }
    return false;
  }
}

class GitRunPlugin extends RunPlugin {
  GitRunPlugin({
    String? activationPrefix,
    List<String> basePath = const [],
    List<Glob> ignores = const [],
  })  : _basePaths = basePath,
        _ignores = ignores,
        super(
          name: "git",
          activationPrefix: activationPrefix ?? ":",
          settings: GSettings("com.github.linux-powertoys.utilities.run.git"),
        );

  List<Glob> _ignores;
  List<Glob> get ignores => _ignores;

  List<String> _basePaths;
  List<String> get basePaths => _basePaths;

  final List<Directory> _gitDirs = [];

  Stream<Directory>? _gitDirStream;

  static String handleVars(String text) {
    RegExp exp = RegExp('\\\$[A-Za-z0-9_]+');
    String result = '';

    int pos = 0;
    for (Match match in exp.allMatches(text)) {
      String varName = text.substring(match.start + 1, match.end);
      String? value = Platform.environment[varName];

      result += text.substring(pos, match.start);
      result += value ?? "";

      pos = match.end;
    }

    result += text.substring(pos);

    return result;
  }

  @override
  Future<void> loadSettings() async {
    super.loadSettings();

    DBusValue searchPaths = await settings.get("search-paths");
    if (searchPaths.signature != DBusSignature.array(DBusSignature.string)) {
      throw const FormatException("gsettings field 'search-path' must be type string array");
    }

    DBusValue excludeSearchPaths = await settings.get("exclude-search-paths");
    if (excludeSearchPaths.signature != DBusSignature.array(DBusSignature.string)) {
      throw const FormatException("gsettings field 'exclude-search-path' must be type string array");
    }

    _basePaths = searchPaths.asStringArray().map((e) => handleVars(e)).toList();
    _ignores = excludeSearchPaths.asStringArray().map((ignore) => Glob(ignore)).toList();
  }

  @override
  Stream<SearchEntry> find(String needle) async* {
    for (Directory dir in _gitDirs) {
      yield _gitDirToSearchEntry(dir);
    }

    if (_gitDirStream == null) return;
    await for (Directory dir in _gitDirStream!) {
      yield _gitDirToSearchEntry(dir);
    }
  }

  @override
  Future<void> fetch() async {
    for (String path in basePaths) {
      Directory dir = Directory(path);
      _gitDirStream = _findGitRepos(dir).asBroadcastStream()
        ..listen((dir) {
          _gitDirs.add(dir);
        });
    }
  }

  static SearchEntry _gitDirToSearchEntry(Directory dir) {
    return SearchEntry(
      title: basename(dir.path),
      subTitle: dir.path,
      icon: const Icon(PluginIcons.git),
      actions: [
        RunAction(
          action: () => GitRunPlugin.launch(dir.path),
          content: const Icon(Icons.open_in_new_outlined),
        ),
        RunAction(
          action: () => GitRunPlugin.openFolder(dir.path),
          content: const Icon(Icons.folder_open_outlined),
        ),
      ],
    );
  }

  static void launch(String path) {
    Process.run("gnome-terminal", ["--working-directory", path]);
  }

  static void openFolder(String path) {
    Process.run("nemo", [path]);
  }

  Stream<Directory> _findGitRepos(Directory root) async* {
    if (basename(root.path) == ".git") {
      yield root.parent;
      return;
    }

    Stream<Directory> dirStream = root
        .list()
        .where((entry) => entry is Directory)
        .map((entity) => entity as Directory)
        .where((dir) => basename(dir.path) == ".git" || !ignores.matchAny(dir.path))
        .map((dir) => _findGitRepos(dir))
        .asyncExpand((dirStream) => dirStream);

    await for (final dir in dirStream) {
      yield dir;
    }
  }
}
