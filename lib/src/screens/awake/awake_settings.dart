import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/awake/awake_backend.dart';
import 'package:linuxpowertoys/src/common_widgets/setting_wrapper.dart';
import 'package:linuxpowertoys/src/common_widgets/stream_listenable_builder.dart';
import 'package:logging/logging.dart';

final _logger = Logger("AwakeSettings");

class AwakeSettings extends StatelessWidget {
  const AwakeSettings({
    super.key,
    required this.enabled,
    required this.backend,
  });

  final bool enabled;
  final AwakeBackend backend;

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() AwakeSettings");
    var textColor = enabled
        ? Theme.of(context).textTheme.bodyMedium?.color
        : Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(90);

    return SettingWrapper(
      title: 'Settings',
      enabled: enabled,
      child: Row(
        children: [
          Text(
            'Keep the computer awake',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: textColor),
          ),
          const Expanded(child: SizedBox()),
          StreamListenableBuilder<bool>(
            initialValue: backend.lastKeepAwake,
            stream: backend.keepAwake,
            builder: (BuildContext context, bool newValue, Widget? child) {
              return Switch(
                value: newValue,
                onChanged: enabled ? backend.setKeepAwake : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
