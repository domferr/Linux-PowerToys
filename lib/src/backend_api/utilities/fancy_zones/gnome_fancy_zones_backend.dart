import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:gsettings/gsettings.dart';
import 'package:linuxpowertoys/src/backend_api/gnome/gnome_extension_utils.dart';
import 'package:linuxpowertoys/src/backend_api/layout.dart';
import 'package:logging/logging.dart';
import 'package:archive/archive_io.dart';

import 'fancy_zones_backend.dart';

/// Backend implementation for the FancyZones utility in the GNOME desktop environment.
class GnomeFancyZonesBackend extends FancyZonesBackend {
  final _logger = Logger('GnomeFancyZonesBackend');
  late final GSettings _mwmSettings;

  final StreamController<bool> _spanMultipleTilesController =
      StreamController<bool>.broadcast();
  bool _lastSpanMultipleZones = false;

  final StreamController<int> _innerGapsController =
  StreamController<int>.broadcast();
  int _lastInnerGaps = 0;

  final StreamController<int> _outerGapsController =
  StreamController<int>.broadcast();
  int _lastOuterGaps = 0;

  final StreamController<List<String>> _selectedLayoutIndexController =
      StreamController<List<String>>.broadcast();
  List<String> _lastSelectedLayouts = [];

  final StreamController<List<Layout>> _layoutsController =
  StreamController<List<Layout>>.broadcast();
  List<Layout> _lastLayouts = [];

  final StreamController<bool> _enableSnapAssistantController =
  StreamController<bool>.broadcast();
  bool _lastEnableSnapAssistant = false;

  /// Stream of the "span multiple zones" value
  @override
  Stream<bool> get spanMultipleZones => _spanMultipleTilesController.stream;

  @override
  bool get lastSpanMultipleZones => _lastSpanMultipleZones;

  /// Stream of the "inner gaps" value.
  @override
  Stream<int> get innerGaps => _innerGapsController.stream;

  @override
  int get lastInnerGaps => _lastInnerGaps;

  /// Stream of the "outer gaps" value.
  @override
  Stream<int> get outerGaps => _outerGapsController.stream;

  @override
  int get lastOuterGaps => _lastOuterGaps;

  /// Stream of the index of the selected layout
  @override
  Stream<List<String>> get selectedLayouts => _selectedLayoutIndexController.stream;

  @override
  List<String> get lastSelectedLayouts => _lastSelectedLayouts;

  /// Stream of the "layouts-json" value.
  @override
  Stream<List<Layout>> get layouts => _layoutsController.stream;

  @override
  List<Layout> get lastLayouts => _lastLayouts;

  /// Stream of the "enable-snap-assist" value.
  @override
  Stream<bool> get enableSnapAssistant => _enableSnapAssistantController.stream;

  @override
  bool get lastEnableSnapAssistant => _lastEnableSnapAssistant;

  /// Creates a new instance of the GnomeFancyZonesBackend.
  GnomeFancyZonesBackend() {
    var homeDir = Platform.environment["HOME"];
    _mwmSettings = GSettings('org.gnome.shell.extensions.modernwindowmanager', schemaDirs: [
      '$homeDir/.local/share/gnome-shell/extensions/modernwindowmanager@ferrarodomenico.com/schemas/'
    ]);
    // initialize settings
    _queryInnerGapsValue();
    _queryOuterGapsValue();
    _querySpanMultipleZonesValue();
    _querySelectedLayouts();
    _queryLayoutsValue();
    _queryEnableSnapAssistant();
    // start listening to changes made to the keys
    _mwmSettings.keysChanged.listen(_handleKeysChanged);
    _lastLayouts = defaultLayouts;
  }

  /// Cleans up any resources used by the backend.
  @override
  void dispose() {
    _mwmSettings.close();
    _spanMultipleTilesController.close();
    _innerGapsController.close();
    _outerGapsController.close();
    _selectedLayoutIndexController.close();
    _layoutsController.close();
    _enableSnapAssistantController.close();
  }

  /// Returns whether the FancyZones extension is currently enabled.
  @override
  Future<bool> isEnabled() async {
    var settings = GSettings('org.gnome.shell');
    var result = await settings
        .get('enabled-extensions')
        .then((res) => res.asStringArray().contains('modernwindowmanager@ferrarodomenico.com'));
    settings.close();
    return result;
  }

  /// Enables or disables the FancyZones extension based on the [newValue] provided.
  @override
  Future<bool> enable(bool newValue) async {
    return GnomeExtensionUtils.enableDisableExtension(
            'modernwindowmanager@ferrarodomenico.com', newValue)
        .then((value) => newValue);
  }

  /// Returns whether the FancyZones extension is installed.
  @override
  Future<bool> isInstalled() async {
    return _mwmSettings.get('inner-gaps').then((value) => true).catchError(
        (_) => false,
        test: (e) => e is GSettingsSchemaNotInstalledException);
  }

  Future<Uint8List> _downloadFile(String url, String dest) async {
    var httpClient = HttpClient();
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    return await consolidateHttpClientResponseBytes(response);
  }

  /// Installs the FancyZones extension.
  @override
  Future<void> install() async {
    final process = await Process.start("gnome-shell", ["--version"], runInShell: true);
    final List<String> standardOutputLines = [];

    await process.stdout
        .transform(utf8.decoder)
        .forEach(standardOutputLines.add);
    String versionPart = standardOutputLines[0].replaceFirst('GNOME Shell', '').trim();
    bool isHigherThan45 = versionPart.startsWith("45") || versionPart.startsWith("46");

    var url = 'https://github.com/domferr/modernwindowmanager/releases/download/7.0.0/GNOME.40-44.modernwindowmanager@ferrarodomenico.com.zip';
    if (isHigherThan45) url = 'https://github.com/domferr/modernwindowmanager/releases/download/7.0.0/modernwindowmanager@ferrarodomenico.com.zip';

    return _downloadFile(url, '/tmp/modernwindowmanager.zip')
        .then((bytes) async {
        final archive = ZipDecoder().decodeBytes(bytes);
        var homeDir = Platform.environment["HOME"];
        extractArchiveToDisk(archive, '$homeDir/.local/share/gnome-shell/extensions/modernwindowmanager@ferrarodomenico.com');
    });

    /*await GnomeExtensionUtils.installRemoteExtension('modernwindowmanager@ferrarodomenico.com')
        .then((value) => setEnableSnapAssistant(false));

    _queryInnerGapsValue();
    _queryOuterGapsValue();
    _querySpanMultipleZonesValue();
    _querySelectedLayouts();
    _queryLayoutsValue();
    _queryEnableSnapAssistant();
    selectLayout(_lastLayouts[0].id);*/
  }

  @override
  Future<void> uninstall() async {
    return GnomeExtensionUtils.uninstallExtension(
        'modernwindowmanager@ferrarodomenico.com')
        .then((value) => true);
  }

  /// Sets the value of the "spanMultipleZones" property to [newValue].
  @override
  setSpanMultipleTiles(bool newValue) {
    _setSetting('enable-span-multiple-tiles', DBusBoolean(newValue));
  }

  /// Sets the value of the "inner gaps" property to [newValue].
  @override
  setInnerGaps(int newValue) {
    _setSetting('inner-gaps', DBusUint32(newValue.round()));
  }

  /// Sets the value of the "outer gaps" property to [newValue].
  @override
  setOuterGaps(int newValue) {
    _setSetting('outer-gaps', DBusUint32(newValue.round()));
  }

  /// Sets the value of the "enable-snap-assist" property to [newValue].
  @override
  setEnableSnapAssistant(bool newValue) {
    _setSetting('enable-snap-assist', DBusBoolean(newValue));
  }

  /// Sets the specified GSettings property [name] to [newValue].
  void _setSetting(final String name, final DBusValue newValue) {
    _mwmSettings.set(name, newValue).onError((err, st) {
      _logger.severe("Cannot SET setting '$name'", err, st);
    });
  }

  /// Handles the keys changed event for the GSettings.
  void _handleKeysChanged(List<String> keys) async {
    for (var changedKey in keys) {
      _logger.info('ModernWindowManager extension. Changed key: $changedKey');
      switch (changedKey) {
        case 'enable-span-multiple-tiles':
          _querySpanMultipleZonesValue();
          break;
        case 'inner-gaps':
          _queryInnerGapsValue();
          break;
        case 'outer-gaps':
          _queryOuterGapsValue();
          break;
        case 'layouts-json':
          _queryLayoutsValue();
          break;
        case 'selected-layouts':
          _querySelectedLayouts();
          break;
        case 'enable-snap-assist':
          _queryEnableSnapAssistant();
          break;
      }
    }
  }

  /// Queries and updates the value of the "spanMultipleZones" property.
  void _querySpanMultipleZonesValue() async {
    try {
      var res = await _mwmSettings.get('enable-span-multiple-tiles');
      _lastSpanMultipleZones = res.asBoolean();
      _spanMultipleTilesController.add(_lastSpanMultipleZones);
    } catch (e) {
      _logger.severe("Failed to get 'enable-span-multiple-tiles' setting", e);
    }
  }

  /// Queries and updates the value of the "inner gaps" property.
  void _queryInnerGapsValue() async {
    try {
      var res = await _mwmSettings.get('inner-gaps');
      _lastInnerGaps = res.asUint32();
      _innerGapsController.add(_lastInnerGaps);
    } catch (e) {
      _logger.severe("Failed to get 'inner-gaps' setting", e);
    }
  }

  /// Queries and updates the value of the "outer gaps" property.
  void _queryOuterGapsValue() async {
    try {
      var res = await _mwmSettings.get('outer-gaps');
      _lastOuterGaps = res.asUint32();
      _outerGapsController.add(_lastOuterGaps);
    } catch (e) {
      _logger.severe("Failed to get 'outer-gaps' setting", e);
    }
  }

  /// Queries and updates the value of the "outer gaps" property.
  void _queryLayoutsValue() async {
    try {
      var res = await _mwmSettings.get('layouts-json');
      var layoutsJson = (jsonDecode(res.asString()) as List).cast<Map<String, dynamic>>();
      _lastLayouts = layoutsJson.map<Layout>((json) => Layout.fromJson(json)).toList();
      _layoutsController.add(_lastLayouts);
    } catch (e) {
      _logger.severe("Failed to get 'layouts-json' setting", e);
    }
  }

  void _querySelectedLayouts() async {
    try {
      var res = await _mwmSettings.get('selected-layouts');
      _lastSelectedLayouts = res.asArray().map((e) => e.asString()).toList();
      _selectedLayoutIndexController.add(_lastSelectedLayouts);
    } catch (e) {
      _logger.severe("Failed to get 'layouts-json' setting", e);
    }
  }

  void _queryEnableSnapAssistant() async {
    try {
      var res = await _mwmSettings.get('enable-snap-assist');
      _lastEnableSnapAssistant = res.asBoolean();
      _enableSnapAssistantController.add(_lastEnableSnapAssistant);
    } catch (e) {
      _logger.severe("Failed to get 'enable-snap-assist' setting", e);
    }
  }

  Future<void> _openLayoutEditor() async {
    var client = DBusClient.session();
    var object = DBusRemoteObject(client,
        name: 'org.gnome.Shell',
        path: DBusObjectPath('/org/gnome/shell/extensions/ModernWindowManager'));
    try {
      await object.callMethod(
          'org.gnome.Shell.Extensions.ModernWindowManager', 'openLayoutEditor', [],
      );
    } on DBusServiceUnknownException {
      _logger.severe('ModernWindowManager service not available');
    }
    return await client.close();
  }

  @override
  Future<void> addLayout(Layout newLayout) async {
    return _openLayoutEditor();
  }

  @override
  Future<void> removeLayout(String layoutId) async {
    if (_lastSelectedLayouts.contains(layoutId)) {
      selectLayout(_lastLayouts[0].id);
    }
    var newLayouts = _lastLayouts.where((element) => (element.id != layoutId)).toList();

    _setSetting(
        'layouts-json',
        DBusString(jsonEncode(newLayouts))
    );
  }

  @override
  Future<void> editLayout(String layoutId) async {
    return _openLayoutEditor();
  }

  @override
  Future<void> selectLayout(String layoutId) async {
    _setSetting(
        'selected-layouts',
        DBusArray(DBusSignature.string, _lastSelectedLayouts.map((e) => DBusString(layoutId)))
    );
  }
}
