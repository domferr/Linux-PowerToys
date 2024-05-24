import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/fancy_zones_backend.dart';
import 'package:linuxpowertoys/src/backend_api/layout.dart';
import 'package:linuxpowertoys/src/common_widgets/setting_wrapper.dart';
import 'package:linuxpowertoys/src/common_widgets/stream_listenable_builder.dart';
import 'package:logging/logging.dart';

import '../../backend_api/tile.dart';

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
                builder: (BuildContext context, List<Layout> layouts,
                    Widget? child) {
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: [
                      ...layouts.mapIndexed((index, thisLayout) => _Layout(
                          enabled: enabled,
                          layout: thisLayout,
                          backend: backend,
                      )),
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

const double layoutWidth = 200;
const double layoutHeight = 200;
const double tilesPadding = 3.0;

class _Layout extends StatelessWidget {
  const _Layout({
    required this.enabled,
    required this.layout,
    required this.backend,
  });

  final bool enabled;
  final Layout layout;
  final FancyZonesBackend backend;

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _Layout of Layout ${layout.id}");

    return StreamListenableBuilder<List<String>>(
        initialValue: backend.lastSelectedLayouts,
        stream: backend.selectedLayouts,
        builder: (BuildContext context, List<String> selectedLayouts, Widget? child) {
          var selected = selectedLayouts.contains(layout.id);
          return ElevatedButton(
            onPressed: enabled ? (() => backend.selectLayout(layout.id)) : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(0),
              fixedSize: const Size(layoutWidth, layoutHeight),
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
              padding: const EdgeInsets.all(tilesPadding),
              child: Stack(
                children: [
                  ...layout.tiles.map((tile) => _SelectableLayout(tile: tile, padding: tilesPadding)),
                  Positioned(
                      top: 0,
                      right: 0,
                      child: Row(
                        children: enabled
                            ? [
                          _ButtonOnLayout(
                            onPressed: () => backend.editLayout(layout.id),
                            icon: Icons.edit,
                            tooltip: "Edit layout",
                          ),
                          !selected
                              ? _ButtonOnLayout(
                            onPressed: () => backend.removeLayout(layout.id),
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

class _SelectableLayout extends StatelessWidget {
  const _SelectableLayout({
    super.key,
    required this.tile,
    this.onTap,
    this.onSecondaryTap,
    this.padding = 0,
    this.child,
  });

  final Tile tile;

  final double padding;
  final void Function()? onTap;
  final void Function()? onSecondaryTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _SelectableLayout");

    var ink = Ink(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: child,
    );

    return Container(
      margin: EdgeInsets.only(left: layoutWidth * tile.x, top: layoutWidth * tile.y),
      width: layoutWidth * tile.width,
      height: layoutHeight * tile.height,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: onTap != null || onSecondaryTap != null
            ? InkWell(
          onTap: onTap,
          onSecondaryTap: onSecondaryTap,
          child: ink,
        )
            : ink,
      ),
    );
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

  void onPressed() {
    backend.addLayout(Layout(id: "id", tiles: []));
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() _NewLayoutButton");

    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(0),
        fixedSize:
            const Size(layoutWidth, layoutHeight),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      child: const Icon(
        Icons.add,
        size: 84,
      )
    );
  }
}
