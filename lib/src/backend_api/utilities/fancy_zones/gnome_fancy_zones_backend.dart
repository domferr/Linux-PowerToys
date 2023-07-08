import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:gsettings/gsettings.dart';
import 'package:linuxpowertoys/src/backend_api/gnome/gnome_extension_utils.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/zone_group.dart';
import 'package:logging/logging.dart';

import 'fancy_zones_backend.dart';

/// Backend implementation for the FancyZones utility in the GNOME desktop environment.
class GnomeFancyZonesBackend extends FancyZonesBackend {
  final _logger = Logger('GnomeFancyZonesBackend');
  late final GSettings _gSnapSettings;

  final StreamController<bool> _spanMultipleZonesController =
      StreamController<bool>.broadcast();
  bool _lastSpanMultipleZones = false;

  final StreamController<int> _windowMarginController =
      StreamController<int>.broadcast();
  int _lastWindowMargin = 0;

  final StreamController<int> _selectedLayoutIndexController =
      StreamController<int>.broadcast();
  int _lastSelectedLayoutIndex = -1;

  final StreamController<List<ZoneGroup>> _layoutsController =
      StreamController<List<ZoneGroup>>.broadcast();
  List<ZoneGroup> _layouts = [];

  /// Stream of the "span multiple zones" value
  @override
  Stream<bool> get spanMultipleZones => _spanMultipleZonesController.stream;

  @override
  bool get lastSpanMultipleZones => _lastSpanMultipleZones;

  /// Stream of the "window margin" value.
  @override
  Stream<int> get windowMargin => _windowMarginController.stream;

  @override
  int get lastWindowMargin => _lastWindowMargin;

  /// Stream of the index of the selected layout
  @override
  Stream<int> get selectedLayoutIndex => _selectedLayoutIndexController.stream;

  @override
  int get lastSelectedLayoutIndex => _lastSelectedLayoutIndex;

  @override
  Stream<List<ZoneGroup>> get layouts => _layoutsController.stream;

  @override
  List<ZoneGroup> get lastLayouts => _layouts;

  /// Creates a new instance of the GnomeFancyZonesBackend.
  GnomeFancyZonesBackend() {
    _gSnapSettings = GSettings('org.gnome.shell.extensions.gsnap');
    // initialize "window margin" and "span multiple zones" settings
    _queryWindowMarginValue();
    _querySpanMultipleZonesValue();
    // start listening to changes made to the keys
    _gSnapSettings.keysChanged.listen(_handleKeysChanged);
    _layouts = defaultLayouts;
  }

  @override
  Future<void> init() async {
    return _loadLayouts();
  }

  /// Cleans up any resources used by the backend.
  @override
  void dispose() {
    _gSnapSettings.close();
    _spanMultipleZonesController.close();
    _windowMarginController.close();
    _selectedLayoutIndexController.close();
  }

  /// Returns whether the FancyZones extension is currently enabled.
  @override
  Future<bool> isEnabled() async {
    var settings = GSettings('org.gnome.shell');
    var result = await settings
        .get('enabled-extensions')
        .then((res) => res.asStringArray().contains('gSnap@micahosborne'));
    settings.close();
    return result;
  }

  /// Enables or disables the FancyZones extension based on the [newValue] provided.
  @override
  Future<bool> enable(bool newValue) async {
    return GnomeExtensionUtils.enableDisableExtension(
            'gSnap@micahosborne', newValue)
        .then((value) => newValue);
  }

  /// Returns whether the FancyZones extension is installed.
  @override
  Future<bool> isInstalled() async {
    return _gSnapSettings.get('window-margin').then((value) => true).catchError(
        (_) => false,
        test: (e) => e is GSettingsSchemaNotInstalledException);
  }

  /// Installs the FancyZones extension.
  @override
  Future<void> install() async {
    await _saveLayouts().onError<Exception>((error, stackTrace) {
      _logger.severe("Cannot save layouts to file", error, stackTrace);
      throw error;
    });
    await GnomeExtensionUtils.installRemoteExtension('gSnap@micahosborne');
    _queryWindowMarginValue();
    _querySpanMultipleZonesValue();
    return selectLayout(0);
  }

  /// Sets the value of the "spanMultipleZones" property to [newValue].
  @override
  setSpanMultipleZones(bool newValue) {
    _setSetting('span-multiple-zones', DBusBoolean(newValue));
  }

  /// Sets the value of the "windowMargin" property to [newValue].
  @override
  setWindowMargin(int newValue) {
    _setSetting('window-margin', DBusInt32(newValue.round()));
  }

  /// Sets the specified GSettings property [name] to [newValue].
  void _setSetting(final String name, final DBusValue newValue) {
    _gSnapSettings.set(name, newValue).onError((err, st) {
      _logger.severe("Cannot SET setting '$name'", err, st);
    });
  }

  /// Handles the keys changed event for the GSettings.
  void _handleKeysChanged(List<String> keys) async {
    for (var changedKey in keys) {
      _logger.info('gSnap extension. Changed key: $changedKey');
      switch (changedKey) {
        case 'span-multiple-zones':
          _querySpanMultipleZonesValue();
          break;
        case 'window-margin':
          _queryWindowMarginValue();
          break;
      }
    }
  }

  /// Queries and updates the value of the "spanMultipleZones" property.
  void _querySpanMultipleZonesValue() async {
    try {
      var res = await _gSnapSettings.get('span-multiple-zones');
      _lastSpanMultipleZones = res.asBoolean();
      _spanMultipleZonesController.add(_lastSpanMultipleZones);
    } catch (e) {
      _logger.severe("Failed to get 'span-multiple-zones' setting", e);
    }
  }

  /// Queries and updates the value of the "windowMargin" property.
  void _queryWindowMarginValue() async {
    try {
      var res = await _gSnapSettings.get('window-margin');
      _lastWindowMargin = res.asInt32();
      _windowMarginController.add(_lastWindowMargin);
    } catch (e) {
      _logger.severe("Failed to get 'window-margin' setting", e);
    }
  }

  Future<void> _loadLayouts() {
    var homeDir = Platform.environment["HOME"];
    return File('$homeDir/.config/gSnap/layouts.json')
        .readAsString()
        .then((jsonContent) {
      var json = jsonDecode(jsonContent);
      var workspaces = json["workspaces"] as List<dynamic>;
      if (workspaces.isEmpty) return;
      // we apply the same layout to all the workspaces and all the monitors
      var firstWorkspace = workspaces[0] as List<dynamic>;
      var monitorSetting =
          firstWorkspace.map((ws) => ws["current"] as int).toList();
      if (monitorSetting[0] < 0) return;

      var definitions = json["definitions"] as List<dynamic>;
      _layouts = definitions
          .map((json) => _jsonToZoneGroup(json as Map<String, dynamic>))
          .toList();
      _layoutsController.add(_layouts);
      _lastSelectedLayoutIndex = monitorSetting[0];
      _selectedLayoutIndexController.add(_lastSelectedLayoutIndex);
    });
  }

  Future<void> _saveLayouts() async {
    var jsonZoneGroups = _layouts.map(_zoneGroupToJson).toList();
    var numberOfWorkspaces =
        3; // it is the total number, taking into account all the monitors
    var numberOfMonitors = 2;
    var monitorsSelection = List.generate(numberOfMonitors,
        (index) => <String, dynamic>{'current': _lastSelectedLayoutIndex});
    var workspaces =
        List.generate(numberOfWorkspaces, (index) => monitorsSelection);
    var finalJson = <String, dynamic>{
      'workspaces': workspaces, // workaround
      'definitions': jsonZoneGroups,
    };
    var jsonEncoded = jsonEncode(finalJson);
    var homeDir = Platform.environment["HOME"];
    File file = File('$homeDir/.config/gSnap/layouts.json');
    file.createSync(recursive: true, exclusive: false);
    return file.writeAsString(jsonEncoded).then((layoutsFile) async {
      _logger.info("Wrote $jsonEncoded to ${layoutsFile.path}");
      await enable(false);
      await enable(true);
    });
  }

  Map<String, dynamic> _zoneGroupToJson(ZoneGroup zoneGroup) {
    var res = <String, dynamic>{
      'type': zoneGroup.props.horizontal ? 0 : 1,
      'length': (zoneGroup.props.perc * 100).toInt(),
    };

    var items = zoneGroup.zones.map(_zoneGroupToJson).toList();
    if (items.isNotEmpty) {
      res['items'] = items;
    }

    return res;
  }

  ZoneGroup _jsonToZoneGroup(Map<String, dynamic> json) {
    var items = json["items"] as List<dynamic>?;
    List<ZoneGroup> zones = items == null
        ? []
        : items
            .map((thisJson) =>
                _jsonToZoneGroup(thisJson as Map<String, dynamic>))
            .toList();

    return ZoneGroup(
      horizontal: json["type"] as int == 0,
      perc: (json["length"] as int) / 100,
      zones: zones,
    );
  }

  @override
  Future<void> addLayout(ZoneGroup newLayout) {
    _layouts.add(newLayout);
    return _saveLayouts().onError<Exception>((error, stackTrace) {
      _logger.severe("Cannot save layouts to file", error, stackTrace);
      _layouts.removeLast();
      throw error;
    }).then((_) => _layoutsController.add(_layouts));
  }

  @override
  Future<void> removeLayoutAt(int index) {
    if (index >= _layouts.length ||
        index < 0 ||
        index == _lastSelectedLayoutIndex) {
      return Future.value();
    }

    ZoneGroup removed = _layouts.removeAt(index);
    return _saveLayouts().onError<Exception>((error, stackTrace) {
      _logger.severe("Cannot save layouts to file", error, stackTrace);
      _layouts.insert(index, removed);
      throw error;
    }).then((_) => _layoutsController.add(_layouts));
  }

  @override
  Future<void> editLayoutAt(int index, ZoneGroup edited) {
    if (index >= _layouts.length || index < 0) return Future.value();

    ZoneGroup oldLayout = _layouts[index];
    _layouts[index] = edited;
    return _saveLayouts().onError<Exception>((error, stackTrace) {
      _logger.severe("Cannot save layouts to file", error, stackTrace);
      _layouts.insert(index, oldLayout);
      throw error;
    }).then((_) => _layoutsController.add(_layouts));
  }

  @override
  Future<void> selectLayout(int newIndex) {
    if (newIndex < 0 ||
        newIndex >= _layouts.length ||
        newIndex == _lastSelectedLayoutIndex) {
      return Future<void>.value();
    }

    var cacheSelectedIndex = _lastSelectedLayoutIndex;
    _lastSelectedLayoutIndex = newIndex;
    return _saveLayouts().onError<Exception>((error, stackTrace) {
      _logger.severe("Cannot save layouts to file", error, stackTrace);
      _lastSelectedLayoutIndex = cacheSelectedIndex;
      throw error;
    }).then((_) {
      _selectedLayoutIndexController.add(_lastSelectedLayoutIndex);
    });
  }
}
