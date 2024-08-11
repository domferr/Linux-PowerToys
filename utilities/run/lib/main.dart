import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../run.dart';
import '../search/search_pannel.dart';
import '../summon/dbus_summoning.dart';

import 'plugins/calculator/calculator.dart';
import 'plugins/git/git.dart';
import 'plugins/plugins.dart';
import 'plugins/visual_studio_code/visual_studio_code.dart';

Future<List<RunPlugin>> loadPlugins() async {
  Logger loadLogger = Logger("plugin loader");

  List<RunPlugin> plugins = [
    CalculatorPlugin(),
    GitRunPlugin(),
    VScodeRunPlugin(),
  ];

  for (int i = 0; i < plugins.length; i++) {
    try {
      await plugins[i].loadSettings();
      loadLogger.severe("loaded '${plugins[i].name}' plugin");
    } catch (e) {
      loadLogger.fine("Failed to load '${plugins[i].name}' plugin settings: $e");
    }
  }

  return plugins;
}

void main() async {
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    developer.log(
      '[${record.level.name}] ${record.message}',
      time: record.time,
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
      zone: record.zone,
      sequenceNumber: record.sequenceNumber,
      name: record.loggerName,
    );
    debugPrint('[${record.level.name}] ${record.time}: ${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();

  RunModel runModel = await RunModel.init();

  List<RunPlugin> plugins = await loadPlugins();

  DBusSummon.register(runModel);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: runModel,
        )
      ],
      child: App(plugins: plugins),
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key, required this.plugins});

  final List<RunPlugin> plugins;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  ThemeMode themeMode = ThemeMode.system;

  bool get useLightMode {
    switch (themeMode) {
      case ThemeMode.system:
        return View.of(context).platformDispatcher.platformBrightness == Brightness.light;
      case ThemeMode.light:
        return true;
      case ThemeMode.dark:
        return false;
    }
  }

  void handleBrightnessChange(bool useLightMode) {
    setState(() {
      themeMode = useLightMode ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    var navigationRailTheme = Theme.of(context).navigationRailTheme.copyWith(
          unselectedLabelTextStyle: Theme.of(context).textTheme.titleMedium,
          selectedLabelTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Linux PowerToys',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
        brightness: Brightness.light,
        navigationRailTheme: navigationRailTheme,
      ),
      darkTheme: ThemeData(
        // colorSchemeSeed: Colors,
        useMaterial3: true,
        brightness: Brightness.dark,
        navigationRailTheme: navigationRailTheme.copyWith(
          selectedLabelTextStyle: navigationRailTheme.selectedLabelTextStyle?.copyWith(color: Colors.white),
          unselectedLabelTextStyle: navigationRailTheme.unselectedLabelTextStyle?.copyWith(color: Colors.white70),
        ),
      ),
      home: RunSearch(plugins: widget.plugins),
    );
  }
}
