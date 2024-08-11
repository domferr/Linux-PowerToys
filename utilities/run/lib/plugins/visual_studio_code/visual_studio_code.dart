import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gsettings/gsettings.dart';
import 'package:path/path.dart';

import '../../plugins/plugins.dart';
import '../../search/search_plugin.dart';

const String kVScodeWorkspaceStoragePath = ".config/Code/User/workspaceStorage";

class VScodeRunPlugin extends RunPlugin {
  VScodeRunPlugin()
      : super(
          name: "VScode",
          activationPrefix: "{",
          settings: GSettings("com.github.linux-powertoys.utilities.run.vscode"),
        );

  final List<VScodeWorkspace> _workspaces = [];

  Stream<VScodeWorkspace>? _fetchStream;
  StreamSubscription<VScodeWorkspace>? _fetchStreamSub;

  @override
  Future<void> fetch() async {
    _fetchStream = VScodeWorkspace.findWorkspaces().asBroadcastStream();
    _fetchStreamSub = _fetchStream?.listen((workspace) {
      _workspaces.add(workspace);
    });

    VScodeWorkspace.workspaceWatcher().listen(_onWorkspacesChanged);

    await _fetchStreamSub?.asFuture();
  }

  void _onWorkspacesChanged(FileSystemEvent event) {
    _fetchStreamSub?.cancel();

    _workspaces.clear();
    _fetchStreamSub = VScodeWorkspace.findWorkspaces().asBroadcastStream().listen((workspace) {
      _workspaces.add(workspace);
    });
  }

  @override
  Stream<SearchEntry> find(String needle) async* {
    for (VScodeWorkspace workspace in _workspaces) {
      yield VSCodeWorkspaceSearchEntry.fromWorkspace(workspace);
    }

    if (_fetchStream == null) return;
    await for (VScodeWorkspace workspace in _fetchStream!) {
      yield VSCodeWorkspaceSearchEntry.fromWorkspace(workspace);
    }
  }
}

extension VSCodeWorkspaceSearchEntry on SearchEntry {
  static SearchEntry fromWorkspace(VScodeWorkspace workspace) {
    return SearchEntry(
      title: workspace.title,
      subTitle: workspace.toString(),
      icon: const Icon(Icons.code_rounded),
      actions: [
        RunAction(
          action: workspace.launch,
          content: const Icon(Icons.open_in_new_outlined),
        ),
      ],
    );
  }
}

class VScodeWorkspaceSSH extends VScodeWorkspace {
  VScodeWorkspaceSSH._({
    required this.user,
    required this.host,
    required super.title,
    required super.uri,
  });

  final String user;
  final String host;

  static const String scheme = "vscode-remote";

  factory VScodeWorkspaceSSH._fromData(Uri uri) {
    Map<String, dynamic> data = _extractUserDataFromUri(uri);

    if (!data.containsKey("hostName")) throw Exception("did not found host");
    if (!data.containsKey("user")) throw Exception("did not found user name");

    return VScodeWorkspaceSSH._(
      title: basename(uri.path),
      uri: uri,
      user: data["user"],
      host: data["hostName"],
    );
  }

  static Map<String, dynamic> _extractUserDataFromUri(Uri uri) {
    String authority = uri.authority;

    int dataBegin = authority.indexOf("%");
    if (dataBegin + 3 >= authority.length) {
      throw Exception("failed to extract username and hostname");
    }

    String hexString = authority.substring(dataBegin + 3);
    List<int> intData = [];
    for (int i = 0; i < hexString.length; i += 2) {
      intData.add(int.parse(hexString.substring(i, i + 2), radix: 16));
    }
    String userData = utf8.decode(intData);
    return jsonDecode(userData);
  }

  @override
  String toString() {
    return "$user@$host:${uri.path}";
  }
}

class VScodeWorkspace {
  VScodeWorkspace({required this.title, required this.uri});

  final String title;
  final Uri uri;

  factory VScodeWorkspace.fromFile(String path) {
    VScodeWorkspace workspace;
    File workspaceDataFile = File(path);

    if (!workspaceDataFile.existsSync()) {
      throw Exception("file does not exist");
    }

    Map<String, dynamic> data = jsonDecode(workspaceDataFile.readAsStringSync());

    if (data.containsKey("folder")) {
      String workspaceUrl = data["folder"];
      Uri uri = Uri.parse(workspaceUrl);
      switch (uri.scheme) {
        case VScodeWorkspaceSSH.scheme:
          workspace = VScodeWorkspaceSSH._fromData(uri);
          break;
        default:
          workspace = VScodeWorkspace(title: Uri.decodeFull(basename(workspaceUrl)), uri: uri);
          break;
      }
    } else {
      String workspaceUrl = data["workspace"];
      workspace = VScodeWorkspace(title: Uri.decodeFull(basename(workspaceUrl)), uri: Uri.parse(workspaceUrl));
    }

    return workspace;
  }

  static String _workspaceDirPathFromPath(String? path) {
    if (path == null && !Platform.environment.containsKey("HOME")) {
      throw Exception("HOME env-variable or path must be specified");
    }

    path ??= join(Platform.environment["HOME"]!, kVScodeWorkspaceStoragePath);
    return path;
  }

  static Stream<VScodeWorkspace> findWorkspaces({String? path}) {
    path ??= _workspaceDirPathFromPath(path);
    Directory dir = Directory(path);

    return dir
        .list()
        .map((directory) => join(directory.path, "workspace.json"))
        .map<VScodeWorkspace?>((workspacePath) {
          try {
            return VScodeWorkspace.fromFile(workspacePath);
          } catch (_) {
            return null;
          }
        })
        .where((workspace) => workspace != null)
        .map((workspace) => workspace!);
  }

  static Stream<FileSystemEvent> workspaceWatcher({String? path}) {
    path ??= _workspaceDirPathFromPath(path);
    Directory dir = Directory(path);
    return dir.watch(events: FileSystemEvent.all);
  }

  @override
  String toString() {
    return Uri.decodeFull(uri.path);
  }

  void launch() {
    Process.run("code", ["--folder-uri", uri.toString()]);
  }
}
