import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/fancy_zones_backend.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/zone_group.dart';
import 'package:linuxpowertoys/src/common_widgets/setting_wrapper.dart';
import 'package:linuxpowertoys/src/common_widgets/stream_listenable_builder.dart';
import 'package:linuxpowertoys/src/screens/fancy_zones/zone_widget.dart';
import 'package:logging/logging.dart';

import 'new_layout_dialog.dart';

final _logger = Logger("LayoutSelection");

class LayoutSelection extends StatelessWidget {
  const LayoutSelection({
    super.key,
    required this.enabled,
    required this.backend,
  });

  final bool enabled;
  final FancyZonesBackend backend;

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() LayoutSelection");

    return SettingWrapper(
        title: 'Layouts',
        enabled: enabled,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: StreamListenableBuilder(
                initialValue: backend.lastLayouts,
                stream: backend.layouts,
                builder: (BuildContext context, List<ZoneGroup> layouts,
                    Widget? child) {
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: [
                      ...layouts
                          .mapIndexed((index, thisLayout) => _SelectableLayout(
                                enabled: enabled,
                                index: index,
                                layout: thisLayout,
                                backend: backend,
                              ))
                          .toList(),
                      _NewLayoutButton(
                        enabled: enabled,
                        backend: backend,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ));
  }
}

const double zonesPadding = 3.0;

class _ZoneGroupBuilder extends StatelessWidget {
  const _ZoneGroupBuilder({
    required this.zoneGroup,
    required this.zoneBuilder,
    this.separatorBuilder,
    this.parent,
    this.indexFromParent = -1,
  });

  final ZoneGroup zoneGroup;
  final Widget Function(ZoneGroup, ZoneGroup?, int) zoneBuilder;

  final Widget Function(
          BuildContext context, int previousZoneIndex, ZoneGroup? parent)?
      separatorBuilder;
  final ZoneGroup? parent;
  final int indexFromParent;

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _ZoneGroupBuilder");

    if (zoneGroup.zones.isEmpty) {
      return zoneBuilder(zoneGroup, parent, indexFromParent);
    }

    var children = zoneGroup.zones
        .mapIndexed((index, zg) => _ZoneGroupBuilder(
            zoneGroup: zg,
            zoneBuilder: zoneBuilder,
            parent: zoneGroup,
            indexFromParent: index,
            separatorBuilder: separatorBuilder))
        .toList();

    List<Widget> finalContent = separatorBuilder == null
        ? children
        : List.generate((children.length * 2) - 1, (index) {
            if (index % 2 == 0) return children[(index / 2).round()];
            /*var previous = zoneGroup.zones[((index-1) / 2).round()];
      var next = zoneGroup.zones[((index+1) / 2).round()];*/
            return separatorBuilder!(
                context, ((index - 1) / 2).round(), zoneGroup);
          });

    return Expanded(
      flex: (zoneGroup.props.perc * 100.0).round(),
      child: zoneGroup.props.horizontal
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: finalContent,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: finalContent,
            ),
    );
  }
}

class _SelectableLayout extends StatelessWidget {
  const _SelectableLayout({
    required this.enabled,
    required this.layout,
    required this.index,
    required this.backend,
  });

  final bool enabled;
  final ZoneGroup layout;
  final int index;
  final FancyZonesBackend backend;

  static const double width = 200;
  static const double height = 200;

  void deleteLayout() {
    backend.removeLayoutAt(index);
  }

  ZoneGroup copyZoneGroup(ZoneGroup source) {
    return ZoneGroup(
      perc: source.props.perc,
      horizontal: source.props.horizontal,
      zones: source.zones.map(copyZoneGroup).toList(),
    );
  }

  void editLayout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => LayoutEditor(
          title: "Edit layout",
          layout: copyZoneGroup(layout),
          onSave: (ZoneGroup edited) => backend.editLayoutAt(index, edited)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _SelectableLayout of Layout $index");

    return StreamListenableBuilder<int>(
        initialValue: backend.lastSelectedLayoutIndex,
        stream: backend.selectedLayoutIndex,
        builder: (BuildContext context, int selectedIndex, Widget? child) {
          var selected = selectedIndex == index;
          return ElevatedButton(
            onPressed: enabled ? (() => backend.selectLayout(index)) : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(0),
              fixedSize: const Size(width, height),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: selected
                        ? Theme.of(context).colorScheme.primary.withAlpha(128)
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: selected ? 2.0 : 0.5),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(zonesPadding),
              child: Stack(
                children: [
                  Column(
                    children: [
                      _ZoneGroupBuilder(
                        zoneGroup: layout,
                        zoneBuilder: (zg, parent, ind) =>
                            ZoneWidget(props: zg.props, padding: zonesPadding),
                      ),
                    ],
                  ),
                  Positioned(
                      top: 0,
                      right: 0,
                      child: Row(
                        children: enabled
                            ? [
                                _ButtonOnLayout(
                                  onPressed: () => editLayout(context),
                                  icon: Icons.edit,
                                  tooltip: "Edit layout",
                                ),
                                !selected
                                    ? _ButtonOnLayout(
                                        onPressed: deleteLayout,
                                        icon: Icons.delete,
                                        tooltip: "Delete layout",
                                      )
                                    : const SizedBox.shrink(),
                              ]
                            : [],
                      )),
                ],
              ),
            ),
          );
        });
  }
}

class _ButtonOnLayout extends StatelessWidget {
  const _ButtonOnLayout({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final void Function()? onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 28.0,
        height: 28.0,
        child: IconButton(
          padding: const EdgeInsets.all(0.0),
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.blueGrey, size: 20.0),
          tooltip: tooltip,
        ),
      ),
    );
  }
}

class _NewLayoutButton extends StatelessWidget {
  const _NewLayoutButton({
    required this.enabled,
    required this.backend,
  });

  final bool enabled;
  final FancyZonesBackend backend;

  static const double width = 200;
  static const double height = 200;

  void onSave(ZoneGroup newLayout) {
    backend.addLayout(newLayout);
  }

  void openDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => LayoutEditor(
          title: "Create new layout",
          layout:
              ZoneGroup(zones: [ZoneGroup(perc: 0.7), ZoneGroup(perc: 0.3)]),
          onSave: onSave),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _NewLayoutButton");

    return ElevatedButton(
        onPressed: enabled ? (() => openDialog(context)) : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          fixedSize:
              const Size(_NewLayoutButton.width, _NewLayoutButton.height),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        child: const Icon(
          Icons.add,
          size: 84,
        ));
  }
}
