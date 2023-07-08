import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/zone_group.dart';
import 'package:linuxpowertoys/src/screens/fancy_zones/zone_widget.dart';
import 'package:logging/logging.dart';

final _logger = Logger('EditableZoneGroup');

class EditableZoneGroup extends StatefulWidget {
  const EditableZoneGroup({
    super.key,
    required this.zoneGroup,
    required this.width,
    required this.height,
    this.onParentSplit,
    this.onParentRemove,
    this.parentIsHorizontal,
  });

  final ZoneGroup zoneGroup;
  final double width;
  final double height;
  final void Function(bool isShiftPressed)? onParentSplit;
  final void Function()? onParentRemove;

  final bool? parentIsHorizontal;

  @override
  State<EditableZoneGroup> createState() => _EditableZoneGroupState();
}

class _EditableZoneGroupState extends State<EditableZoneGroup> {
  late List<double> sizes;

  double separatorPadding = 2.0;
  double separatorSize = 12.0;
  double minPercentage = 0.1;

  @override
  void initState() {
    super.initState();
    sizes = createSizes();
  }

  @override
  void didUpdateWidget(EditableZoneGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.height != widget.height ||
        oldWidget.width != widget.width ||
        oldWidget.zoneGroup.zones.length != widget.zoneGroup.zones.length) {
      sizes = createSizes();
    }
  }

  List<double> createSizes() {
    var parentSize =
        widget.zoneGroup.props.horizontal ? widget.width : widget.height;
    return widget.zoneGroup.zones.mapIndexed((index, zone) {
      double separatorDim =
          index == widget.zoneGroup.zones.length - 1 ? 0.0 : separatorSize;
      return (zone.props.perc * parentSize) - separatorDim;
    }).toList();
  }

  void addZoneAt(int index, bool isShiftPressed) {
    var zoneAtIndex = widget.zoneGroup.zones[index];
    var oldPerc = zoneAtIndex.props.perc;
    zoneAtIndex.props.perc = oldPerc / 2;
    // avoid splitting into two zones lower than 10%
    if (zoneAtIndex.props.perc < minPercentage) return;

    widget.zoneGroup.zones
        .insert(index + 1, ZoneGroup(perc: oldPerc - zoneAtIndex.props.perc));
    zoneAtIndex.props.horizontal = !isShiftPressed;

    setState(() {
      sizes = createSizes();
    });
  }

  void splitCurrentZone(bool isShiftPressed) {
    widget.zoneGroup.zones = [ZoneGroup(perc: 0.5), ZoneGroup(perc: 0.5)];
    widget.zoneGroup.props.horizontal = !isShiftPressed;
    setState(() {
      sizes = createSizes();
    });
  }

  void onZoneTap() {
    if (widget.parentIsHorizontal == null) return;

    final shiftKeys = [
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight
    ];
    final isShiftPressed = RawKeyboard.instance.keysPressed
        .where((it) => shiftKeys.contains(it))
        .isNotEmpty;

    if (widget.parentIsHorizontal == isShiftPressed) {
      splitCurrentZone(isShiftPressed);
    } else {
      widget.onParentSplit!(isShiftPressed);
    }
  }

  void removeZoneAt(int index) {
    if (index == -1 || index >= widget.zoneGroup.zones.length) return;

    var zones = widget.zoneGroup.zones;
    ZoneGroup removed = zones.removeAt(index);
    int nearestIndex = index == zones.length ? (index - 1) : index;
    zones[nearestIndex].props.perc += removed.props.perc;

    if (widget.zoneGroup.zones.length == 1) {
      widget.zoneGroup.zones = [];
    }

    setState(() {
      sizes = createSizes();
    });
  }

  void onResizeZones(int previousZoneIndex, double mainSize, double mouseOffset,
      double mouseDelta) {
    // zone before separator
    var previousZone = widget.zoneGroup.zones[previousZoneIndex];
    // zone after separator
    var nextZone = widget.zoneGroup.zones[previousZoneIndex + 1];

    double sizeBeforeZonePairs = 0;
    for (int i = 0; i < previousZoneIndex; i++) {
      sizeBeforeZonePairs += sizes[i] + separatorSize;
    }

    // check if the mouse goes to much too the left. Ensure left zone does not go below 10%.
    // But ensure that 10% is reachable even if the user does a very fast movement to the left
    if (mouseDelta > 0 &&
        mouseOffset < (minPercentage * mainSize) + sizeBeforeZonePairs) {
      return;
    }

    // check if the mouse goes to much too the right. Ensure right zone does not go below 10%
    // But ensure that 10% is reachable even if the user does a very fast movement to the right
    if (mouseDelta < 0 &&
        mouseOffset >
            ((previousZone.props.perc + nextZone.props.perc - minPercentage) *
                    mainSize) -
                separatorSize +
                sizeBeforeZonePairs) {
      return;
    }

    // size of the zone before the separator
    var oldPrevSize = sizes[previousZoneIndex];
    // new size of the zone before the separator
    var newSize = sizes[previousZoneIndex] + mouseDelta;
    var oldPrevPerc = previousZone.props.perc;
    var totalPercentage = oldPrevPerc + nextZone.props.perc;
    var newPrevPerc = (oldPrevPerc * newSize) / oldPrevSize;
    var newNextPrec = totalPercentage - newPrevPerc;
    // avoid going below 10% for both previous and next zones
    if (newPrevPerc < minPercentage || newNextPrec < minPercentage) return;

    previousZone.props.perc = newPrevPerc;
    nextZone.props.perc = newNextPrec;

    sizes[previousZoneIndex] += mouseDelta;
    sizes[previousZoneIndex + 1] -= mouseDelta;
    setState(() {
      sizes = sizes;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _EditableZoneGroupState");

    if (widget.zoneGroup.zones.isEmpty) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: Row(
          children: [
            ZoneWidget(
              props: widget.zoneGroup.props,
              onTap: onZoneTap,
              onSecondaryTap: widget.onParentRemove,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${(widget.zoneGroup.props.perc * 100).toStringAsFixed(2)}%",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.color
                                  ?.withAlpha(128),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    List<Widget> finalContent =
        List.generate((widget.zoneGroup.zones.length * 2) - 1, (index) {
      var isHorizontal = widget.zoneGroup.props.horizontal;

      if (index % 2 == 0) {
        var thisSize = sizes[(index / 2).round()];
        var thisZone = widget.zoneGroup.zones[(index / 2).round()];
        return EditableZoneGroup(
          width: isHorizontal ? thisSize : widget.width,
          height: isHorizontal ? widget.height : thisSize,
          zoneGroup: thisZone,
          parentIsHorizontal: widget.zoneGroup.props.horizontal,
          onParentSplit: (bool isShiftPressed) {
            addZoneAt((index / 2).round(), isShiftPressed);
          },
          onParentRemove: () {
            removeZoneAt((index / 2).round());
          },
        );
      }

      return SizedBox(
        height: isHorizontal ? (separatorSize * 5) : separatorSize,
        width: isHorizontal ? separatorSize : (separatorSize * 5),
        child: Padding(
          padding: EdgeInsets.all(separatorPadding),
          child: MouseRegion(
            cursor: isHorizontal
                ? SystemMouseCursors.resizeLeftRight
                : SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                if (!isHorizontal) return;

                final RenderBox? renderBox =
                    context.findRenderObject() as RenderBox?;
                if (renderBox == null) return;
                var mouseOffset =
                    renderBox.globalToLocal(details.globalPosition);
                var localMouseOffset = mouseOffset.dx;
                onResizeZones(((index - 1) / 2).round(), widget.width,
                    localMouseOffset, details.delta.dx);
              },
              onVerticalDragUpdate: (DragUpdateDetails details) {
                if (isHorizontal) return;

                final RenderBox? renderBox =
                    context.findRenderObject() as RenderBox?;
                if (renderBox == null) return;
                var mouseOffset =
                    renderBox.globalToLocal(details.globalPosition);
                var localMouseOffset = mouseOffset.dy;
                onResizeZones(((index - 1) / 2).round(), widget.height,
                    localMouseOffset, details.delta.dy);
              },
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
              ),
            ),
          ),
        ),
      );
    });

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: widget.zoneGroup.props.horizontal
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: finalContent,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: finalContent,
            ),
    );
  }
}
