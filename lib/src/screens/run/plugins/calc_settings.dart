import 'package:flutter/material.dart';
import 'package:gsettings/gsettings.dart';
import 'package:provider/provider.dart';

import '../../../backend_api/utilities/run/run_plugin_backend.dart';
import '../run_plugin_settings.dart';

class RunCalcSettingsBackend extends RunPluginSettings {
  RunCalcSettingsBackend() : super(GSettings("com.github.linux-powertoys.utilities.run.calc"));
}

class RunCalcSettings extends StatefulWidget {
  const RunCalcSettings({super.key});

  @override
  State<RunCalcSettings> createState() => _RunCalcSettingsState();
}

class _RunCalcSettingsState extends State<RunCalcSettings> {
  @override
  Widget build(BuildContext context) {
    return RunPluginSettingsWrapper(
      settings: Provider.of<RunCalcSettingsBackend>(context),
      error: Provider.of<RunCalcSettingsBackend>(context).error,
      title: "calc",
      description: "quicly calculator simple expresions",
      leading: const Icon(Icons.calculate_outlined),
      children: const [],
    );
  }
}
