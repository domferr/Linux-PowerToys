import 'dart:math';

import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/zone_group.dart';
import 'package:logging/logging.dart';

import 'editable_zone_group.dart';

final _logger = Logger('LayoutEditor');

class LayoutEditor extends StatelessWidget {
  const LayoutEditor({
    super.key,
    required this.title,
    required this.layout,
    required this.onSave,
  });

  final String title;
  final ZoneGroup layout;
  final void Function(ZoneGroup newLayout) onSave;

  final double maxWidth = 700;
  final double maxHeight = 700;

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _NewLayoutButton");

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        height: maxWidth,
        width: maxHeight,
        child: Column(
          children: [
            const InstructionsTable(),
            const SizedBox(height: 36),
            Expanded(
              child: Card(
                  margin: const EdgeInsets.all(0),
                  child: LayoutEditorContainer(
                    layout: layout,
                  )),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Dismiss'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FilledButton(
          child: const Text('Save'),
          onPressed: () {
            onSave(layout);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class ActionSuggestion extends StatelessWidget {
  const ActionSuggestion({super.key, required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(48),
            spreadRadius: 0,
            blurRadius: 0,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              action,
              style:
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class LayoutEditorContainer extends StatelessWidget {
  const LayoutEditorContainer({
    super.key,
    required this.layout,
  });

  final ZoneGroup layout;

  final double newLayoutPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(newLayoutPadding),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double newLayoutSize =
              min(constraints.maxWidth, constraints.maxHeight);
          return SizedBox(
            width: newLayoutSize,
            height: newLayoutSize,
            child: Column(
              children: [
                EditableZoneGroup(
                  zoneGroup: layout,
                  width: newLayoutSize,
                  height: newLayoutSize,
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class InstructionsTable extends StatelessWidget {
  const InstructionsTable({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var textStyle = Theme.of(context).textTheme.labelLarge;

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        TableRow(
          children: <Widget>[
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [ActionSuggestion(action: "LEFT CLICK")],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ActionSuggestion(action: "LEFT CLICK"),
                Text(' + ', style: textStyle),
                const ActionSuggestion(action: "SHIFT"),
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionSuggestion(action: "RIGHT CLICK"),
              ],
            ),
          ],
        ),
        TableRow(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(' on a zone to split it horizontally. ',
                      style: textStyle),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(' on a zone to split it vertically. ',
                      style: textStyle),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(' on a zone to remove it. ', style: textStyle),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
