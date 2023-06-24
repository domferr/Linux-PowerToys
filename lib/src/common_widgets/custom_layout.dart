import 'package:flutter/material.dart';

import 'setting_wrapper.dart';

const horizontalPadding = 32.0;

class CustomLayout extends StatelessWidget {
  const CustomLayout({
    super.key,
    required this.titleWidget,
    required this.children,
    this.enableWidget,
  });
  
  final Widget titleWidget;
  final Widget? enableWidget;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            child: Padding(
              padding: const EdgeInsets.all(horizontalPadding),
              child: titleWidget,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: horizontalPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
                if (enableWidget != null) enableWidget!,
                ...children,
                const SizedBox(height: horizontalPadding),
              ]
            ),
          ),
        ),
      ],
    );
  }
}