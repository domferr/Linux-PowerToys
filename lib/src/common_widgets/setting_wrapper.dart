import 'package:flutter/material.dart';

import 'custom_card.dart';

const verticalPadding = 20.0;

class SettingWrapper extends StatelessWidget {
  const SettingWrapper({
    super.key,
    required this.child,
    required this.enabled,
    this.title
  });

  final Widget child;
  final bool enabled;
  final String? title;

  @override
  Widget build(BuildContext context) {
    var textColor = enabled ?
    Theme.of(context).textTheme.bodyMedium?.color:
    Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(90);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title != null ? Padding(
          padding: const EdgeInsets.only(
            top: verticalPadding,
            bottom: 8.0
          ),
          child: Text(title!,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor
            ),
          ),
        ):const SizedBox.shrink(),
        const SizedBox(height: 8.0),
        CustomCard(
          child: child,
        ),
      ],
    );
  }
}