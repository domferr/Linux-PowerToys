import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/awake/awake_backend.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/awake/gnome_awake_backend.dart';
import 'package:linuxpowertoys/src/common_widgets/credits.dart';
import 'package:linuxpowertoys/src/common_widgets/screen_layout.dart';
import 'package:logging/logging.dart';

import 'awake_settings.dart';

class AwakeScreen extends StatefulWidget {
  const AwakeScreen({
    super.key,
  });

  @override
  State<AwakeScreen> createState() => _AwakeScreenState();
}

class _AwakeScreenState extends State<AwakeScreen> {
  final _logger = Logger('AwakeScreen');
  final AwakeBackend backend = GnomeAwakeBackend();

  bool isEnabled = false;
  bool isInstalled = true;

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
      _logger.severe("Cannot install Awake utility", error, stackTrace);
      return false;
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
          "Cannot check if Awake utility is enabled", error, stackTrace);
      return false;
    });

    setState(() {
      isEnabled = utilityIsEnabled;
      isInstalled = true;
    });
  }

  Future<void> handleInstallPressed() async {
    backend.install().then((_) => asyncInitState());
  }

  Future<void> handleEnableChange(bool newValue) async {
    var enableResult = await backend
        .enable(newValue)
        .then((_) => newValue)
        .onError((error, stackTrace) {
      _logger.severe("Cannot ${newValue ? 'enable' : 'disable'} Awake utility",
          error, stackTrace);
      return isEnabled;
    });

    setState(() {
      isEnabled = enableResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _AwakeScreenState");
    const imgUrl =
        'https://cdn.pixabay.com/photo/2017/04/19/13/03/coffee-2242213_1280.jpg';

    return ScreenLayout(
      title: "Awake",
      description:
          "Keep the computer awake effortlessly, avoiding sleep or screen shutdown without the need to manage power and sleep settings.",
      image: Image.network(
        imgUrl,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) {
          _logger.severe("Cannot use image at url $imgUrl", error);
          return const SizedBox();
        },
      ),
      isInstalled: isInstalled,
      handleInstallPressed: handleInstallPressed,
      isEnabled: isEnabled,
      handleEnableChange: handleEnableChange,
      enableTitle: "Enable Awake",
      credits: const Credits(
          name: "caffeine",
          url: "https://github.com/eonpatapon/gnome-shell-extension-caffeine"),
      children: isInstalled
          ? [
              AwakeSettings(enabled: isEnabled, backend: backend),
            ]
          : [],
    );
  }
}
