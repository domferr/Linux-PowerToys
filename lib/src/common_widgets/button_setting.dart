import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/common_widgets/setting_wrapper.dart';

class ButtonSetting extends StatelessWidget {
  const ButtonSetting({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.settingDescription,
    this.color,
    this.title,
  });

  final void Function() onPressed;
  final String? title;
  final String label;
  final String settingDescription;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {

    return SettingWrapper(
      title: title,
      enabled: true,
      child: Row(
        children: [
          Text(
            settingDescription,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
          ),
          const Expanded(child: SizedBox()),
          FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: color != null ? FilledButton.styleFrom(
              backgroundColor: color
            ):null,
          )
        ],
      ),
    );
  }
}
