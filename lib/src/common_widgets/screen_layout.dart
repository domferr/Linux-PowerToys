import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/common_widgets/custom_layout.dart';
import 'package:logging/logging.dart';

import 'setting_wrapper.dart';

const horizontalPadding = 32.0;

class ScreenLayout extends StatelessWidget {
  ScreenLayout({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    required this.isEnabled,
    required this.handleEnableChange,
    required this.enableTitle,
    required this.children,
    this.credits,
    this.isInstalled = true,
    this.handleInstallPressed,
  });

  final logger = Logger('ScreenLayout');

  final String title;
  final String description;
  final Widget image;
  final bool isEnabled;
  final Future<void> Function(bool)? handleEnableChange;
  final String enableTitle;
  final List<Widget> children;

  final Widget? credits;
  final bool isInstalled;
  final Future<void> Function()? handleInstallPressed;

  @override
  Widget build(BuildContext context) {
    return CustomLayout(
        titleWidget: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12), // Image border
              child: SizedBox.fromSize(
                size: const Size(280, 200), // Image radius
                child: image,
              ),
            ),
            const SizedBox(
              width: horizontalPadding,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Title(
                      title: title,
                      showInstallButton: !isInstalled,
                      onInstallPressed: handleInstallPressed),
                  const SizedBox(height: 36.0),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
        enableWidget: !isInstalled
            ? null
            : _EnableUtility(
                title: enableTitle,
                enabled: isEnabled,
                handleEnableChange: handleEnableChange),
        children: [
          ...children,
          const SizedBox(height: 16.0),
          credits ?? const SizedBox.shrink()
        ]);
  }
}

class _Title extends StatefulWidget {
  const _Title({
    required this.title,
    required this.showInstallButton,
    required this.onInstallPressed,
  });

  final String title;
  final bool showInstallButton;
  final Future<void> Function()? onInstallPressed;

  @override
  State<_Title> createState() => _TitleState();
}

class _TitleState extends State<_Title> {
  bool installing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> handleInstallation() async {
    if (widget.onInstallPressed == null) return;

    setState(() {
      installing = true;
    });

    await widget.onInstallPressed!();

    setState(() {
      installing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var titleWidget = Text(
      widget.title,
      style: Theme.of(context)
          .textTheme
          .displaySmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
    return widget.showInstallButton
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              titleWidget,
              const SizedBox(width: 12.0),
              FilledButton.icon(
                onPressed: handleInstallation,
                label: Text(installing ? 'Installing' : 'Install'),
                icon: const Icon(Icons.download_for_offline_rounded),
              ),
            ],
          )
        : titleWidget;
  }
}

class _EnableUtility extends StatelessWidget {
  const _EnableUtility({
    required this.title,
    required this.enabled,
    required this.handleEnableChange,
  });

  final String title;
  final void Function(bool)? handleEnableChange;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    var lightMode = Theme.of(context).brightness == Brightness.light;
    Color successColor =
        lightMode ? Colors.green.shade500 : Colors.green.shade900;
    Color selectedThumbColor = lightMode ? Colors.white : Colors.white70;

    return SettingWrapper(
      enabled: enabled,
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Expanded(child: Container()),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              handleEnableChange == null
                  ? 'Disabled'
                  : (enabled ? 'On' : 'Off'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Switch(
            value: handleEnableChange != null && enabled,
            onChanged: handleEnableChange,
            trackColor: MaterialStateProperty.resolveWith(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return successColor;
                }
                return null;
              },
            ),
            thumbColor: MaterialStateProperty.resolveWith(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return selectedThumbColor;
                }
                return null;
              },
            ),
            thumbIcon: MaterialStateProperty.resolveWith(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Icon(Icons.check, color: successColor);
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
