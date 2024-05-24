import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/backend_api/utility_backend.dart';
import 'package:linuxpowertoys/src/common_widgets/setting_wrapper.dart';

import 'custom_card.dart';

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
          ElevatedButton.icon(
            onPressed: onUninstall,
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text("Uninstall",
                style: TextStyle(color: Colors.white)
            ),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red),
            ),
          )
        ],
      ),
    );
  }
}
