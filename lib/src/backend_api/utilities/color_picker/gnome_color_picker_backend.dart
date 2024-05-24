import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:gsettings/gsettings.dart';
import 'package:linuxpowertoys/src/backend_api/gnome/gnome_extension_utils.dart';
import 'package:logging/logging.dart';

import 'color_picker_backend.dart';

/// Concrete implementation of the "Awake" backend for the Gnome desktop environment.
class GnomeColorPickerBackend extends ColorPickerBackend {
  final _logger = Logger('GnomeColorPickerBackend');

  final StreamController<List<String>> _colorsHistoryController =
  StreamController<List<String>>.broadcast();
  List<String> _lastColorsHistory = [];

  @override
  Stream<List<String>> get colorsHistory => _colorsHistoryController.stream;

  @override
  List<String> get lastColorsHistory => _lastColorsHistory;

  final StreamController<bool> _automaticallyCopyController =
  StreamController<bool>.broadcast();
  bool _lastAutomaticallyCopy = false;

  @override
  Stream<bool> get automaticallyCopy => _automaticallyCopyController.stream;

  @override
  bool get lastAutomaticallyCopy => _lastAutomaticallyCopy;

  late final GSettings _colorPickerSettings;

  /// Constructs a new instance of [GnomeColorPickerBackend].
  GnomeColorPickerBackend() {
    _logger.info("GnomeColorPickerBackend");
    var homeDir = Platform.environment["HOME"];
    _colorPickerSettings = GSettings(
      'org.gnome.shell.extensions.color-picker',
      schemaDirs: [
        '$homeDir/.local/share/gnome-shell/extensions/color-picker@tuberry/schemas/'
      ],
    );

    _queryColorsHistory();
    _queryAutomaticallyCopy();
    _colorPickerSettings.keysChanged.listen(_handleKeysChanged);
  }

  @override
  void dispose() {
    _colorPickerSettings.close();
  }

  @override
  Future<bool> isEnabled() async {
    var settings = GSettings('org.gnome.shell');
    var result = await settings
        .get('enabled-extensions')
        .then((res) => res.asStringArray().contains('color-picker@tuberry'));
    settings.close();
    return result;
  }

  @override
  Future<bool> enable(bool newValue) async {
    return GnomeExtensionUtils.enableDisableExtension(
            'color-picker@tuberry', newValue)
        .then((value) {
      _queryColorsHistory();
      _queryAutomaticallyCopy();
      return true;
    });
  }

  @override
  Future<bool> isInstalled() async {
    return _colorPickerSettings.get('enable-systray').then((value) => true).onError(
        (error, stackTrace) => false,
        test: (e) => e is GSettingsSchemaNotInstalledException);
  }

  @override
  Future<bool> install() async {
    return await GnomeExtensionUtils.installRemoteExtension('color-picker@tuberry')
      .then((_) {
        var elapsed = 0;
        final completer = Completer<bool>();
        Timer.periodic(const Duration(milliseconds: 600), (timer) async {
          if (await isInstalled()) {
            /*_setSetting('notify-style', const DBusInt32(1));
            _setSetting('preview-style', const DBusInt32(1));*/
            _setSetting('enable-systray', const DBusBoolean(true));
            _setSetting('enable-shortcut', const DBusBoolean(true));
            _setSetting('color-picker-shortcut', DBusArray(DBusSignature.string, [const DBusString('<Shift><Super>c')]));

            _queryColorsHistory();
            _queryAutomaticallyCopy();
            timer.cancel();
            completer.complete(true);
            return;
          }
          elapsed += 5;
          if (elapsed >= 60) {
            timer.cancel();
            completer.complete(false);
          }
        });
        return completer.future;
    });
  }

  @override
  Future<void> uninstall() async {
    return GnomeExtensionUtils.uninstallExtension(
        'color-picker@tuberry')
        .then((value) => true);
  }

  @override
  setColorsHistory(List<String> newValue) {
    // set the setting to <newValue>
    _setSetting('colors-history', DBusString(newValue.reversed.join("|")));
  }

  void _setSetting(final String name, final DBusValue newValue) {
    _colorPickerSettings
        .set(name, newValue)
        .then((value) => _logger.info("Set '$name' setting to $newValue"))
        .onError((err, st) {
      _logger.severe("Cannot SET setting '$name'", err, st);
    });
  }

  void _handleKeysChanged(List<String> keys) async {
    for (var changedKey in keys) {
      _logger.info('Color-Picker extension. Changed key: $changedKey');
      switch (changedKey) {
        case 'colors-history':
          _queryColorsHistory();
          break;
        case 'auto-copy':
          _queryAutomaticallyCopy();
          break;
      }
    }
  }

  void _queryColorsHistory() async {
    try {
      var res = await _colorPickerSettings.get('colors-history');
      _lastColorsHistory = res.asString().split("|").reversed.toList();
      _colorsHistoryController.add(_lastColorsHistory);
    } catch (e) {
      _logger.severe("Failed to get 'colors-history' setting", e);
    }
  }

  void _queryAutomaticallyCopy() async {
    try {
      var res = await _colorPickerSettings.get('auto-copy');
      _lastAutomaticallyCopy = res.asBoolean();
      _automaticallyCopyController.add(_lastAutomaticallyCopy);
    } catch (e) {
      _logger.severe("Failed to get 'auto-copy' setting", e);
    }
  }

  @override
  setAutomaticallyCopy(bool newValue) {
    _setSetting('auto-copy', DBusBoolean(newValue));
  }
}
