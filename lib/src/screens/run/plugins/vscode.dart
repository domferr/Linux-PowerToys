import 'package:flutter/material.dart';
import 'package:gsettings/gsettings.dart';
import 'package:provider/provider.dart';

import '../../../backend_api/utilities/run/run_plugin_backend.dart';
import '../run_plugin_settings.dart';

class RunVSCodeSettingsBackend extends RunPluginSettings {
  RunVSCodeSettingsBackend() : super(GSettings("com.github.linux-powertoys.utilities.run.vscode"));
}

class RunVSCodeSettings extends StatefulWidget {
  const RunVSCodeSettings({super.key});

  @override
  State<RunVSCodeSettings> createState() => _RunVSCodeSettingsState();
}

class _RunVSCodeSettingsState extends State<RunVSCodeSettings> {
  @override
  Widget build(BuildContext context) {
    return RunPluginSettingsWrapper(
      settings: Provider.of<RunVSCodeSettingsBackend>(context),
      error: Provider.of<RunVSCodeSettingsBackend>(context).error,
      description: "lists all VSCode workspaces",
      title: "VSCode",
      leading: const Icon(Icons.code),
      children: const [],
    );
  }
}
