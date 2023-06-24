import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:linuxpowertoys/src/backend_api/fancy_zones/fancy_zones_backend.dart';
import 'package:linuxpowertoys/src/backend_api/fancy_zones/zone_group.dart';
import 'package:linuxpowertoys/src/backend_api/fancy_zones/zone_props.dart';
import 'package:linuxpowertoys/src/common_widgets/setting_wrapper.dart';
import 'package:linuxpowertoys/src/common_widgets/stream_listenable_builder.dart';
import 'package:logging/logging.dart';

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

    return SettingWrapper(title: 'Layouts', enabled: enabled,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16.0,
              runSpacing: 16.0,
              children: backend.layouts.mapIndexed((index, zoneGroup) =>
                _SelectableLayout(
                  enabled: enabled,
                  index: index,
                  zoneGroup: zoneGroup,
                  backend: backend,
                )
              ).toList(),
            ),
          ),
        ],
      )
    );
  }
}

class _SelectableLayout extends StatelessWidget {
  const _SelectableLayout({
    super.key,
    required this.enabled,
    required this.zoneGroup,
    required this.index,
    required this.backend,
  });

  final bool enabled;
  final ZoneGroup zoneGroup;
  final int index;
  final FancyZonesBackend backend;

  static const double width = 200;
  static const double height = 200;
  static const double selectedButtonSideWidth = 2.0;
  static const double zonesPadding = 3.0;
  static const innerWidth = width - selectedButtonSideWidth;
  static const innerHeight = height - selectedButtonSideWidth;

  Widget buildZoneGroup(ZoneGroup group, double parentWidth, double parentHeight, ZoneProps parentProps) {
    if (group.zones.isEmpty) {
      return _Zone(
          props: group.props,
          parentProps: parentProps,
          parentWidth: parentWidth,
          parentHeight: parentHeight,
          padding: zonesPadding
      );
    }

    var thisGroupWidth = parentProps.horizontal ? (parentWidth * group.props.perc):parentWidth;
    var thisGroupHeight = parentProps.horizontal ? parentHeight:(parentHeight * group.props.perc);

    var children = group.zones.map((zg) =>
        buildZoneGroup(zg, thisGroupWidth, thisGroupHeight, group.props)
    ).toList();

    if (group.props.horizontal) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: children,
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: children,
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
          onPressed: enabled ? (() => backend.selectLayout(index)):null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(0),
            fixedSize: const Size(width, height),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                  color: selected ?
                  Theme.of(context).colorScheme.primary.withAlpha(128):
                  Theme.of(context).colorScheme.outlineVariant,
                  width: selected ? selectedButtonSideWidth:0.5
              ),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
          ),
          child: SizedBox(
            width: innerWidth - (zonesPadding * 2),
            height: innerHeight - (zonesPadding * 2),
            child: buildZoneGroup(zoneGroup, innerWidth, innerHeight, zoneGroup.props),
          ),
        );
      }
    );
  }
}

class _Zone extends StatelessWidget {
  const _Zone({
    super.key,
    required this.props,
    required this.parentProps,
    required this.parentWidth,
    required this.parentHeight,
    required this.padding,
  });

  final ZoneProps props;
  final ZoneProps parentProps;
  final double parentWidth;
  final double parentHeight;
  final double padding;

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _Zone");

    double widthPerc = parentProps.horizontal ? props.perc:1;
    double heightPerc = parentProps.horizontal ? 1:props.perc;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Ink(
        width: (parentWidth * widthPerc) - (padding * 4),
        height: (parentHeight * heightPerc) - (padding * 4),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Theme.of(context).buttonTheme.colorScheme?.primary.withAlpha(28),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
      ),
    );
  }
}