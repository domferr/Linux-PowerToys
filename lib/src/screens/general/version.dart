import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/common_widgets/setting_wrapper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Version extends StatelessWidget {
  const Version({
    super.key,
    required this.packageInfo,
  });

  final PackageInfo packageInfo;

  @override
  Widget build(BuildContext context) {

    return SettingWrapper(title: 'Version', enabled: true,
      child: Row(
        children: [
          Text(
            'v${packageInfo.version}+${packageInfo.buildNumber}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Expanded(child: Container()),
          ElevatedButton(
            onPressed: () {
              launchUrl(Uri.parse("https://github.com/domferr/Linux-PowerToys/releases"));
            },
            child: const Text("Check for updates")
          ),
        ],
      ),
    );
  }
}