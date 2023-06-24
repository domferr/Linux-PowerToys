import 'package:flutter/material.dart';

const cardInternalPadding = EdgeInsets.symmetric(
    horizontal: 16.0, vertical: 20.0
);

class CustomCard extends StatefulWidget {
  const CustomCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  final focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Focus(
        focusNode: focusNode,
        canRequestFocus: true,
        child: GestureDetector(
          onTapDown: (_) {
            focusNode.requestFocus();
          },
          behavior: HitTestBehavior.opaque,
          child: Card(
            margin: const EdgeInsets.all(0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: cardInternalPadding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}