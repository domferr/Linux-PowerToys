import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:gsettings/gsettings.dart';
import 'package:linuxpowertoys/src/backend_api/fancy_zones/zone_group.dart';
import 'package:logging/logging.dart';

import 'fancy_zones_backend.dart';
import '../gnome_extension_utils.dart';

/// Backend implementation for the FancyZones utility in the GNOME desktop environment.
class GnomeFancyZonesBackend extends FancyZonesBackend {

  final _logger = Logger('GnomeFancyZonesBackend');
  late final GSettings _gSnapSettings;

  final StreamController<bool> _spanMultipleZonesController = StreamController<bool>.broadcast();
  bool _lastSpanMultipleZones = false;

  final StreamController<int> _windowMarginController = StreamController<int>.broadcast();
  int _lastWindowMargin = 0;

  final StreamController<int> _selectedLayoutIndexController = StreamController<int>.broadcast();
  int _lastSelectedLayoutIndex = -1;

  /// Stream of the "span multiple zones" value
  @override
  Stream<bool> get spanMultipleZones => _spanMultipleZonesController.stream;

  @override
  bool get lastSpanMultipleZones => _lastSpanMultipleZones;

  @override
  int get lastWindowMargin => _lastWindowMargin;

  /// Stream of the "window margin" value.
  @override
  Stream<int> get windowMargin => _windowMarginController.stream;
  
  /// Stream of the index of the selected layout
  @override
  Stream<int> get selectedLayoutIndex => _selectedLayoutIndexController.stream;

  @override
  int get lastSelectedLayoutIndex => _lastSelectedLayoutIndex;

  /// Creates a new instance of the GnomeFancyZonesBackend.
  GnomeFancyZonesBackend() {
    _gSnapSettings = GSettings('org.gnome.shell.extensions.gsnap');
    // initialize "window margin" and "span multiple zones" settings
    _queryWindowMarginValue();
    _querySpanMultipleZonesValue();
    // start listening to changes made to the keys
    _gSnapSettings.keysChanged.listen(_handleKeysChanged);
    _readLayoutSettings();
  }

  /// Cleans up any resources used by the backend.
  @override
  void dispose() {
    _gSnapSettings.close();
    _spanMultipleZonesController.close();
    _windowMarginController.close();
  }

  /// Returns whether the FancyZones extension is currently enabled.
  @override
  Future<bool> isEnabled() async {
    var settings = GSettings('org.gnome.shell');
    var result = await settings.get('enabled-extensions')
        .then((res) => res.asStringArray().contains('gSnap@micahosborne'));
    settings.close();
    return result;
  }

  /// Enables or disables the FancyZones extension based on the [newValue] provided.
  @override
  Future<bool> enable(bool newValue) async {
    return GnomeExtensionUtils.enableDisableExtension('gSnap@micahosborne', newValue).then((value) => newValue);
  }

  /// Returns whether the FancyZones extension is installed.
  @override
  Future<bool> isInstalled() async {
    return _gSnapSettings.get('window-margin')
    .then((value) => true)
    .catchError((_) => false, test: (e) => e is GSettingsSchemaNotInstalledException);
  }

  /// Installs the FancyZones extension.
  @override
  Future<bool> install() async {
    return GnomeExtensionUtils.installRemoteExtension('gSnap@micahosborne')
    .then((_) {
      selectLayout(0);
      _queryWindowMarginValue();
      _querySpanMultipleZonesValue();
      return true;
    });
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

  void _readLayoutSettings() {
    var homeDir = Platform.environment["HOME"];
    File('$homeDir/.config/gSnap/layouts.json').readAsString()
    .then((jsonContent) {
      var json = jsonDecode(jsonContent);
      var workspaces = json["workspaces"] as List<dynamic>;
      if (workspaces.isEmpty) return;
      // we apply the same layout to all the workspaces and all the monitors
      var firstWorkspace = workspaces[0] as List<dynamic>;
      var monitorSetting = firstWorkspace.map((ws) => ws["current"] as int).toList();
      if (monitorSetting[0] < 0) return;
      _lastSelectedLayoutIndex = monitorSetting[0];
      _selectedLayoutIndexController.add(_lastSelectedLayoutIndex);
    });
  }

  Map<String, dynamic> _zoneGroupToJson(ZoneGroup zoneGroup) {
    var res = <String, dynamic>{
      'type': zoneGroup.props.horizontal ? 0:1,
      'length': (zoneGroup.props.perc * 100).toInt(),
    };

    var items = zoneGroup.zones.map(_zoneGroupToJson).toList();
    if (items.isNotEmpty) {
      res['items'] = items;
    }

    return res;
  }

  /*ZoneGroup _layoutsJsonToZoneGroup(Map<String, dynamic> decodedJson) {
    var length = decodedJson["length"] as int;
    var type = decodedJson["type"] as int?;
    var horizontal = type == null ? true:type != 1;
    var items = decodedJson["items"] as List<Map<String, dynamic>>?;
    List<ZoneGroup> zones = [];
    if (items != null) {
      zones = items.map(_layoutsJsonToZoneGroup).toList();
    }

    return ZoneGroup(perc: length / 100, horizontal: horizontal, zones: zones);
  }*/

  @override
  void selectLayout(int newIndex) {
    if (newIndex < 0 || newIndex >= layouts.length) return;

    var jsonZoneGroups = layouts.map(_zoneGroupToJson).toList();
    var numberOfWorkspaces = 3; // it is the total number, taking into account all the monitors
    var numberOfMonitors = 2;
    var monitorsSelection = List.generate(numberOfMonitors, (index) => <String, dynamic>{'current': newIndex});
    var workspaces = List.generate(numberOfWorkspaces, (index) => monitorsSelection);
    var finalJson = <String, dynamic>{
      'workspaces': workspaces, // workaround
      'definitions': jsonZoneGroups,
    };
    var jsonEncoded = jsonEncode(finalJson);
    var homeDir = Platform.environment["HOME"];
    File('$homeDir/.config/gSnap/layouts.json').writeAsString(jsonEncoded)
    .then((layoutsFile) async {
      _logger.info("Wrote $jsonEncoded to ${layoutsFile.path}");
      await enable(false);
      await enable(true);
      _lastSelectedLayoutIndex = newIndex;
      _selectedLayoutIndexController.add(_lastSelectedLayoutIndex);
    });
  }
}