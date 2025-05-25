import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/common_widgets/setting_wrapper.dart';

class UninstallSetting extends StatelessWidget {
  const UninstallSetting({
    super.key,
    required this.onUninstall,
  });

  final void Function() onUninstall;

  @override
  Widget build(BuildContext context) {

    return SettingWrapper(
      title: 'Uninstall',
      enabled: true,
      child: Row(
        children: [
          Text(
            'Uninstall the utility',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
          ),
          const Expanded(child: SizedBox()),
          OutlinedButton.icon(
            onPressed: onUninstall,
            icon: const Icon(Icons.delete),
            label: const Text("Uninstall"),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(width: 1.0, color: Colors.red),
              foregroundColor: Colors.red
            ),
          )
        ],
      ),
    );
  }
}
