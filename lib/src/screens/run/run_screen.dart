import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/backend_api/utilities/run/run_backend.dart';
import '../../../src/common_widgets/screen_layout.dart';
import '../../../src/common_widgets/setting_wrapper.dart';
import '../../backend_api/utilities/run/plugins/run_plugin_git_bakcned.dart';
import './plugins/calc_settings.dart';
import './plugins/git_settings.dart';
import './plugins/vscode.dart';

class RunScreen extends StatefulWidget {
  const RunScreen({
    super.key,
  });

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  RunBackend run = RunBackend();

  SettingKeyBindingController summonKeybindingController = SettingKeyBindingController();

  @override
  void initState() {
    super.initState();

    run.fetch();
    run.addListener(() {
      summonKeybindingController.keys = run.summonKeybinding;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            RunGitSettingsBackend settings = RunGitSettingsBackend.fromInterface(
              "com.github.linux-powertoys.utilities.run.git",
            );
            settings.fetchSettingsSave();

            return settings;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            RunCalcSettingsBackend settings = RunCalcSettingsBackend();
            settings.fetchSettingsSave();

            return settings;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            RunVSCodeSettingsBackend settings = RunVSCodeSettingsBackend();
            settings.fetchSettingsSave();

            return settings;
          },
        ),
      ],
      builder: (context, _) => ListenableBuilder(
        listenable: run,
        builder: (context, _) => Theme(
          data: Theme.of(context).copyWith(extensions: [
            SettingsTheme.fromContext(
              context,
              enabled: run.enabled,
            ),
          ]),
          child: ScreenLayout(
            title: "Run",
            description: "Run is quick launcher",
            image: const Image(image: AssetImage('assets/images/Run.png')),
            isInstalled: true,
            isEnabled: run.enabled,
            handleEnableChange: (enabled) async {
              run.enabled = enabled;
            },
            handleInstallPressed: () async {},
            enableTitle: "Enable Run",
            children: [
              SettingWrapper(
                enabled: run.enabled,
                title: "Search Settings",
                child: Column(
                  children: [
                    SettingKeyBinding(
                      title: "Activation",
                      controller: summonKeybindingController,
                      onChange: (keys) => run.summonKeybinding = keys,
                    ),
                  ],
                ),
              ),
              const SettingHeader(title: "Plugins"),
              const RunGitSettings(),
              const RunCalcSettings(),
              const RunVSCodeSettings(),
            ],
          ),
        ),
      ),
    );
  }
}
