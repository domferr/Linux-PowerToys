import 'package:linuxpowertoys/src/backend_api/tile.dart';
import 'package:linuxpowertoys/src/backend_api/utility_backend.dart';

import '../../layout.dart';

/// Abstract class representing the backend for the "FancyZones" utility.
abstract class FancyZonesBackend extends UtilityBackend {
  /// Stream for the "span multiple zones" status.
  Stream<bool> get spanMultipleZones;

  /// get the last "span multiple zones" value.
  bool get lastSpanMultipleZones;

  /// Sets the "span multiple zones" status to the specified [newValue].
  setSpanMultipleTiles(bool newValue);

  /// Stream for the "window margin" value.
  Stream<int> get innerGaps;

  /// Sets the window margin value to the specified [newValue].
  setInnerGaps(int newValue);

  /// get the last "inner gaps" value.
  int get lastInnerGaps;

  /// Stream for the "outer gaps" value.
  Stream<int> get outerGaps;

  /// Sets the outer gaps value to the specified [newValue].
  setOuterGaps(int newValue);

  /// get the last "outer gaps" value.
  int get lastOuterGaps;

  /// Stream for listening to layouts change.
  Stream<List<Layout>> get layouts;

  /// get the last layouts.
  List<Layout> get lastLayouts;

  /// Stream for listening to changes on the selected layout.
  Stream<List<String>> get selectedLayouts;

  /// get the last selected layout index.
  List<String> get lastSelectedLayouts;

  /// Select the layout at index [index]
  Future<void> selectLayout(String layoutId);

  /// Add the given layout to the list of layouts
  Future<void> addLayout(Layout newLayout);

  /// Remove the given layout from the list of layouts
  Future<void> removeLayout(String layoutId);

  /// Edit the layout
  Future<void> editLayout(String layoutId);

  /// get the default layouts
  List<Layout> get defaultLayouts => [
    Layout(id: "the id", tiles: [
      Tile(x: 0, y: 0, width: 0.22, height: 0.5),
      Tile(x: 0, y: 0.5, width: 0.22, height: 0.5),
      Tile(x: 0.22, y: 0, width: 0.56, height: 1),
      Tile(x: 0.78, y: 0, width: 0.22, height: 0.5),
      Tile(x: 0.78, y: 0.5, width: 0.22, height: 0.5),
    ])
  ];

  /// Stream for the "enable snap assistant" value.
  Stream<bool> get enableSnapAssistant;

  /// Sets the enable snap assistant value to the specified [newValue].
  setEnableSnapAssistant(bool newValue);

  /// get the last "enable snap assistant" value.
  bool get lastEnableSnapAssistant;
}
