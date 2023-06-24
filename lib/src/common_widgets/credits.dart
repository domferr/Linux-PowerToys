import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Credits extends StatelessWidget {
  const Credits({
    required this.name,
    required this.url,
  });

  final String name;
  final String url;

  Future<void> _openWebPage() async {
    Uri urlUri = Uri.parse(url);
    if (!await launchUrl(urlUri)) {
      throw 'Could not launch $urlUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          const TextSpan(text: 'Powered by '),
          TextSpan(
            text: name,
            style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue
            ),
            recognizer: TapGestureRecognizer()..onTap = _openWebPage,
          ),
          const TextSpan(text: ' '),
          const WidgetSpan(
            child: Icon(
              Icons.open_in_new,
              size: 14,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}