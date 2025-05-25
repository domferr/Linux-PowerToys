import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/common_widgets/custom_layout.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:linuxpowertoys/src/screens/general/version.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
              child: Image.asset(
                "assets/images/General.png",
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stackTrace) {
                  _logger.severe(
                      "Cannot load asset image assets/images/General.png",
                      error);
                  return const SizedBox();
                },
              ),
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
                Text(
                  "Welcome!",
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16.0),
                Text(
                  "Let's bring Power Toys to the Linux world!",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48.0),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: spaceBetweenLinks,
                  runSpacing: 6,
                  children: [
                    LinkText(
                        url: 'https://github.com/domferr/Linux-PowerToys',
                        placeholder: 'GitHub repository'),
                    LinkText(
                        url:
                            'https://github.com/domferr/Linux-PowerToys/issues',
                        placeholder: 'Report a bug'),
                    LinkText(
                        url:
                            'https://github.com/domferr/Linux-PowerToys/issues',
                        placeholder: 'Request a feature'),
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
        const SizedBox(height: horizontalPadding),
        const _Donations(),
        const SizedBox(height: horizontalPadding),
      ],
    );
  }
}

class _Donations extends StatelessWidget {
  const _Donations();

  @override
  Widget build(BuildContext context) {
    return const Row(
        children: [
          Expanded(child: SizedBox()),
          Padding(
            padding: EdgeInsets.only(right: 24.0),
            child: _DonationButton(
              text: "Donate on Ko-fi", 
              url: "https://ko-fi.com/domferr", 
              icon: SimpleIcons.kofi,
              iconColor: Colors.white,
              color: Color(0xff29ABE0),
            ),
          ),
          _DonationButton(
            text: "Become a Patreon", 
            url: "https://patreon.com/domferr", 
            color: Colors.deepOrange,
            icon: SimpleIcons.patreon,
            iconColor: Colors.black,
          ),
          Expanded(child: SizedBox()),
        ],
    );
  }
}

class _DonationButton extends StatelessWidget {
  const _DonationButton({
    required this.text,
    required this.url,
    required this.color,
    required this.icon,
    this.iconColor,
  });

  final String url;
  final String text;
  final Color color;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          await (launchUrlString(url));
        } catch (e) {
          debugPrint("Error: $e");
        }
      },
      icon: Icon(
        icon,
        color: iconColor,
      ),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color
      ),
    );
  }
}