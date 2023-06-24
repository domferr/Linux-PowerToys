import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/screens/general/version.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../common_widgets/custom_layout.dart';
import 'link_text.dart';

const horizontalPadding = 32.0;

class GeneralScreen extends StatefulWidget {
  const GeneralScreen({Key? key}) : super(key: key);

  @override
  State<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends State<GeneralScreen> {

  final _logger = Logger('GeneralScreenState');

  PackageInfo _packageInfo = PackageInfo(
    appName: '',
    packageName: '',
    version: '',
    buildNumber: '',
    buildSignature: '',
    installerStore: '',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    const spaceBetweenLinks = 32.0;
    return CustomLayout(
      titleWidget: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12), // Image border
            child: SizedBox.fromSize(
              size: const Size(280, 200), // Image radius
              child: Image.asset("assets/images/General.png",
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stackTrace) {
                  _logger.severe("Cannot load asset image assets/images/General.png", error);
                  return const SizedBox();
                },
              ),
            ),
          ),
          const SizedBox(width: horizontalPadding,),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Welcome",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16.0),
                Text(
                  "Let's bring Power Toys to the Linux world!",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48.0),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LinkText(
                        url: 'https://github.com/domferr/Linux-PowerToys',
                        placeholder: 'GitHub repository'
                    ),
                    SizedBox(width: spaceBetweenLinks),
                    LinkText(
                        url: 'https://github.com/domferr/Linux-PowerToys/issues',
                        placeholder: 'Report a bug'
                    ),
                    SizedBox(width: spaceBetweenLinks),
                    LinkText(
                        url: 'https://github.com/domferr/Linux-PowerToys/issues',
                        placeholder: 'Request a feature'
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
      children: [
        Version(
          packageInfo: _packageInfo,
        ),
        const SizedBox(height: horizontalPadding)
      ],
    );
  }
}