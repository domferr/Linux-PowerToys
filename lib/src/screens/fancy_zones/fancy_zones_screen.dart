import 'dart:async';

import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/fancy_zones_backend.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/gnome_fancy_zones_backend.dart';
import 'package:linuxpowertoys/src/common_widgets/credits.dart';
import 'package:linuxpowertoys/src/common_widgets/screen_layout.dart';
import 'package:linuxpowertoys/src/common_widgets/setting_wrapper.dart';
import 'package:linuxpowertoys/src/common_widgets/stream_listenable_builder.dart';
import 'package:logging/logging.dart';

import '../../common_widgets/uninstall_setting.dart';
import 'layout_selection.dart';

final _logger = Logger('FancyZonesScreen');

class FancyZonesScreen extends StatefulWidget {
  const FancyZonesScreen({
    super.key,
  });

  @override
  State<FancyZonesScreen> createState() => _FancyZonesScreenState();
}

class _FancyZonesScreenState extends State<FancyZonesScreen> {
  bool isInstalled = true;
  bool isEnabled = false;

  final FancyZonesBackend backend = GnomeFancyZonesBackend();

  @override
  void initState() {
    super.initState();
    asyncInitState();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    backend.dispose();
  }

  Future<void> asyncInitState() async {
    var extensionInstalled =
        await backend.isInstalled().onError((error, stackTrace) {
      _logger.severe(
          "Cannot check if FancyZones utility is installed", error, stackTrace);
      return isInstalled;
    });

    if (!extensionInstalled) {
      setState(() {
        isInstalled = false;
      });
      return;
    }
    var utilityIsEnabled =
        await backend.isEnabled().onError((error, stackTrace) {
      _logger.severe(
          "Cannot check if FancyZones utility is enabled", error, stackTrace);
      return isEnabled;
    });

    setState(() {
      isEnabled = utilityIsEnabled;
      isInstalled = true;
    });
  }

  Future<void> _openDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fancy Zones installed!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('To enable and use the Fancy Zones, a restart is needed.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> handleInstallPressed() async {
    backend.install().then((_) async {
      await asyncInitState();
      _openDialog();
      return backend.enable(true);
    });
  }

  Future<void> handleEnableChange(bool newValue) async {
    var enableResult = await backend
        .enable(newValue)
        .then((_) => newValue)
        .onError((error, stackTrace) {
      _logger.severe(
          "Cannot ${newValue ? 'enable' : 'disable'} Fancy Zones utility",
          error,
          stackTrace);
      return isEnabled;
    });

    setState(() {
      isEnabled = enableResult;
    });
  }

  void handleUninstallPressed() {
    backend.uninstall().then((_) => asyncInitState());
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _FancyZonesScreenState");

    return ScreenLayout(
      title: "Fancy Zones",
      description:
          "FancyZones organizes windows into efficient layouts, enhancing workflow speed and restoring layouts quickly. It allows you to define zone positions for desktop windows, resizing and repositioning them through dragging or shortcuts.",
      image: Image.asset(
        "assets/images/FancyZones.png",
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) {
          _logger.severe(
              "Cannot load asset image assets/images/FancyZones.png", error);
          return const SizedBox();
        },
      ),
      isEnabled: isEnabled,
      handleEnableChange: handleEnableChange,
      isInstalled: isInstalled,
      handleInstallPressed: handleInstallPressed,
      enableTitle: "Enable Fancy Zones",
      credits: const Credits(
          name: "ModernWindowManager", url: "https://github.com/domferr/modernwindowmanager"),
      children: isInstalled
          ? [
              _ActivationShortcut(
                enabled: isEnabled,
                backend: backend,
              ),
              _EnableSnapAssistant(
                enabled: isEnabled,
                backend: backend,
              ),
              _SpanMultipleZones(
                enabled: isEnabled,
                backend: backend,
              ),
              _InnerGaps(
                enabled: isEnabled,
                backend: backend,
              ),
              _OuterGaps(
                enabled: isEnabled,
                backend: backend,
              ),
              LayoutSelection(
                enabled: isEnabled,
                backend: backend,
              ),
              UninstallSetting(
                  onUninstall: handleUninstallPressed
              ),
            ]
          : [],
    );
  }
}

class _ActivationShortcut extends StatelessWidget {
  const _ActivationShortcut({
    required this.enabled,
    required this.backend,
  });

  final bool enabled;
  final FancyZonesBackend backend;

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _ActivationShortcut");

    var textColor = enabled
        ? Theme.of(context).textTheme.bodyMedium?.color
        : Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(90);

    return SettingWrapper(
        enabled: enabled,
        child: Row(
          children: [
            Text(
              'Activation shortcut',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textColor),
            ),
            const Expanded(child: SizedBox()),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withAlpha(enabled ? 255 : 96),
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withAlpha(48),
                    spreadRadius: 0,
                    blurRadius: 0,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: SizedBox(
                  width: 60,
                  height: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "CTRL",
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  )),
            ),
          ],
        ));
  }
}

class _SpanMultipleZones extends StatelessWidget {
  const _SpanMultipleZones({
    required this.enabled,
    required this.backend,
  });

  final bool enabled;
  final FancyZonesBackend backend;

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _SpanMultipleZones");

    var textColor = enabled
        ? Theme.of(context).textTheme.bodyMedium?.color
        : Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(90);

    return SettingWrapper(
        title: 'Settings',
        enabled: enabled,
        child: Row(
          children: [
            Text(
              'Span multiple zones by pressing ALT key',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textColor),
            ),
            const Expanded(child: SizedBox()),
            StreamListenableBuilder<bool>(
              initialValue: backend.lastSpanMultipleZones,
              stream: backend.spanMultipleZones,
              builder: (BuildContext context, bool newValue, Widget? child) {
                return Switch(
                  value: newValue,
                  onChanged: enabled ? backend.setSpanMultipleTiles : null,
                );
              },
            ),
          ],
        ));
  }
}

class _EnableSnapAssistant extends StatelessWidget {
  const _EnableSnapAssistant({
    required this.enabled,
    required this.backend,
  });

  final bool enabled;
  final FancyZonesBackend backend;

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _EnableSnapAssistant");

    var textColor = enabled
        ? Theme.of(context).textTheme.bodyMedium?.color
        : Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(90);

    return SettingWrapper(
        title: "Snap Assistant",
        enabled: enabled,
        child: Row(
          children: [
            Text(
              'Move the window near the top of the screen to activate the Snap Assistant.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textColor),
            ),
            const Expanded(child: SizedBox()),
            StreamListenableBuilder<bool>(
              initialValue: backend.lastEnableSnapAssistant,
              stream: backend.enableSnapAssistant,
              builder: (BuildContext context, bool newValue, Widget? child) {
                return Switch(
                  value: newValue,
                  onChanged: enabled ? backend.setEnableSnapAssistant : null,
                );
              },
            ),
          ],
        ));
  }
}

class _InnerGaps extends StatefulWidget {
  const _InnerGaps({required this.enabled, required this.backend});

  final bool enabled;
  final FancyZonesBackend backend;

  @override
  State<_InnerGaps> createState() => _InnerGapsState();
}

class _InnerGapsState extends State<_InnerGaps> {
  double _innerGaps = 0;
  late StreamSubscription<int> streamSubscription;

  @override
  void initState() {
    super.initState();
    _innerGaps = widget.backend.lastInnerGaps.toDouble();
    streamSubscription = widget.backend.innerGaps.listen((int newValue) {
      setState(() {
        _innerGaps = newValue.toDouble();
      });
    });
  }

  void handleInnerGapsChangeEnd(double newValue) {
    widget.backend.setInnerGaps(newValue.round());
  }

  @override
  void dispose() {
    streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _InnerGapsState");

    var textColor = widget.enabled
        ? Theme.of(context).textTheme.bodyMedium?.color
        : Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(90);

    return SettingWrapper(
        enabled: widget.enabled,
        child: Row(
          children: [
            Text(
              'Apply spacing between windows',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textColor),
            ),
            const Expanded(child: SizedBox()),
            Text(
              "${_innerGaps.round()}",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textColor),
            ),
            SizedBox(
              width: 256,
              child: Slider(
                max: 48,
                divisions: 48,
                value: _innerGaps,
                label: _innerGaps.round().toString(),
                onChangeEnd:
                    widget.enabled ? handleInnerGapsChangeEnd : null,
                onChanged: widget.enabled
                    ? (double newVal) => setState(() {
                          _innerGaps = newVal;
                        })
                    : null,
              ),
            ),
          ],
        ));
  }
}

class _OuterGaps extends StatefulWidget {
  const _OuterGaps({required this.enabled, required this.backend});

  final bool enabled;
  final FancyZonesBackend backend;

  @override
  State<_OuterGaps> createState() => _OuterGapsState();
}

class _OuterGapsState extends State<_OuterGaps> {
  double _outerGaps = 0;
  late StreamSubscription<int> streamSubscription;

  @override
  void initState() {
    super.initState();
    _outerGaps = widget.backend.lastOuterGaps.toDouble();
    streamSubscription = widget.backend.outerGaps.listen((int newValue) {
      setState(() {
        _outerGaps = newValue.toDouble();
      });
    });
  }

  void handleOuterGapsChangeEnd(double newValue) {
    widget.backend.setOuterGaps(newValue.round());
  }

  @override
  void dispose() {
    streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _OuterGapsState");

    var textColor = widget.enabled
        ? Theme.of(context).textTheme.bodyMedium?.color
        : Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(90);

    return SettingWrapper(
        enabled: widget.enabled,
        child: Row(
          children: [
            Text(
              'Apply spacing between the screen and the windows',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textColor),
            ),
            const Expanded(child: SizedBox()),
            Text(
              "${_outerGaps.round()}",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textColor),
            ),
            SizedBox(
              width: 256,
              child: Slider(
                max: 48,
                divisions: 48,
                value: _outerGaps,
                label: _outerGaps.round().toString(),
                onChangeEnd:
                widget.enabled ? handleOuterGapsChangeEnd : null,
                onChanged: widget.enabled
                    ? (double newVal) => setState(() {
                  _outerGaps = newVal;
                })
                    : null,
              ),
            ),
          ],
        ));
  }
}
