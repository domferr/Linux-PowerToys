import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkText extends StatelessWidget {
  const LinkText({
    super.key,
    required this.placeholder,
    required this.url,
  });

  final String placeholder;
  final String url;

  _launchURL(String url) async {
    Uri urlUri = Uri.parse(url);
    if (!await launchUrl(urlUri)) {
      throw 'Could not launch $urlUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _launchURL(url);
      },
      child: Text(
        placeholder,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade600,
            ),
      ),
    );
  }
}
