import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'dart:developer' as developer;
import 'package:window_size/window_size.dart';

import 'src/constants.dart';
import 'src/home.dart';

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    developer.log(
        '[${record.level.name}] ${record.message}',
        time: record.time,
        level: record.level.value,
        error: record.error,
        stackTrace: record.stackTrace,
        zone: record.zone,
        sequenceNumber: record.sequenceNumber,
        name: record.loggerName
    );
    debugPrint('[${record.level.name}] ${record.time}: ${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();

  setWindowTitle('Linux PowerToys');
  setWindowMinSize(const Size(700, 500));
  setWindowMaxSize(Size.infinite);

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  ThemeMode themeMode = ThemeMode.system;

  bool get useLightMode {
    switch (themeMode) {
      case ThemeMode.system:
        return View.of(context).platformDispatcher.platformBrightness ==
            Brightness.light;
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
      selectedLabelTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold
      )
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Linux PowerToys',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: baseColor),
        useMaterial3: true,
        brightness: Brightness.light,
        navigationRailTheme: navigationRailTheme,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: baseColor,
        useMaterial3: true,
        brightness: Brightness.dark,
        navigationRailTheme: navigationRailTheme.copyWith(
          selectedLabelTextStyle: navigationRailTheme.selectedLabelTextStyle?.copyWith(
            color: Colors.white
          ),
          unselectedLabelTextStyle: navigationRailTheme.unselectedLabelTextStyle?.copyWith(
            color: Colors.white70
          ),
        ),
      ),
      home: Home(
        useLightMode: useLightMode,
        handleBrightnessChange: handleBrightnessChange
      ),
    );
  }
}
