import 'dart:async';

import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/fancy_zones_backend.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/gnome_fancy_zones_backend.dart';
import 'package:linuxpowertoys/src/common_widgets/credits.dart';
import 'package:linuxpowertoys/src/common_widgets/screen_layout.dart';
import 'package:linuxpowertoys/src/common_widgets/setting_wrapper.dart';
import 'package:linuxpowertoys/src/common_widgets/stream_listenable_builder.dart';
import 'package:logging/logging.dart';

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

    backend.init();

    setState(() {
      isEnabled = utilityIsEnabled;
      isInstalled = true;
    });
  }

  Future<void> handleInstallPressed() async {
    backend.install().then((_) async {
      await asyncInitState();
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
          name: "gSnap", url: "https://github.com/GnomeSnapExtensions/gSnap"),
      children: isInstalled
          ? [
              _ActivationShortcut(
                enabled: isEnabled,
                backend: backend,
              ),
              _SpanMultipleZones(
                enabled: isEnabled,
                backend: backend,
              ),
              _WindowMargin(
                enabled: isEnabled,
                backend: backend,
              ),
              LayoutSelection(
                enabled: isEnabled,
                backend: backend,
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
                  onChanged: enabled ? backend.setSpanMultipleZones : null,
                );
              },
            ),
          ],
        ));
  }
}

class _WindowMargin extends StatefulWidget {
  const _WindowMargin({required this.enabled, required this.backend});

  final bool enabled;
  final FancyZonesBackend backend;

  @override
  State<_WindowMargin> createState() => _WindowMarginState();
}

class _WindowMarginState extends State<_WindowMargin> {
  double _windowMargin = 0;
  late StreamSubscription<int> streamSubscription;

  @override
  void initState() {
    super.initState();
    _windowMargin = widget.backend.lastWindowMargin.toDouble();
    streamSubscription = widget.backend.windowMargin.listen((int newValue) {
      setState(() {
        _windowMargin = newValue.toDouble();
      });
    });
  }

  void handleWindowMarginChangeEnd(double newValue) {
    widget.backend.setWindowMargin(newValue.round());
  }

  @override
  void dispose() {
    streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _WindowMargin");

    var textColor = widget.enabled
        ? Theme.of(context).textTheme.bodyMedium?.color
        : Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(90);

    return SettingWrapper(
        enabled: widget.enabled,
        child: Row(
          children: [
            Text(
              'Apply a margin to all the windows',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textColor),
            ),
            const Expanded(child: SizedBox()),
            Text(
              "${_windowMargin.round()}",
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
                value: _windowMargin,
                label: _windowMargin.round().toString(),
                onChangeEnd:
                    widget.enabled ? handleWindowMarginChangeEnd : null,
                onChanged: widget.enabled
                    ? (double newVal) => setState(() {
                          _windowMargin = newVal;
                        })
                    : null,
              ),
            ),
          ],
        ));
  }
}
