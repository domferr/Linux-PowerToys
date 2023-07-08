import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/zone_group.dart';
import 'package:linuxpowertoys/src/backend_api/utility_backend.dart';

/// Abstract class representing the backend for the "FancyZones" utility.
abstract class FancyZonesBackend extends UtilityBackend {
  Future<void> init();

  /// Stream for the "span multiple zones" status.
  Stream<bool> get spanMultipleZones;

  /// get the last "span multiple zones" value.
  bool get lastSpanMultipleZones;

  /// Sets the "span multiple zones" status to the specified [newValue].
  setSpanMultipleZones(bool newValue);

  /// Stream for the "window margin" value.
  Stream<int> get windowMargin;

  /// Sets the window margin value to the specified [newValue].
  setWindowMargin(int newValue);

  /// get the last "window margin" value.
  int get lastWindowMargin;

  /// Stream for listening to layouts change.
  Stream<List<ZoneGroup>> get layouts;

  /// get the last layouts.
  List<ZoneGroup> get lastLayouts;

  /// Stream for listening to changes on the selected layout.
  Stream<int> get selectedLayoutIndex;

  /// get the last selected layout index.
  int get lastSelectedLayoutIndex;

  /// Select the layout at index [index]
  Future<void> selectLayout(int newIndex);

  /// Add the given layout to the list of layouts
  Future<void> addLayout(ZoneGroup newLayout);

  /// Remove the given layout from the list of layouts
  Future<void> removeLayoutAt(int index);

  /// Edit the layout from the posi
  Future<void> editLayoutAt(int index, ZoneGroup edited);

  /// get the default layouts
  List<ZoneGroup> get defaultLayouts => [
        ZoneGroup(zones: [ZoneGroup(perc: 0.4), ZoneGroup(perc: 0.6)]),
        ZoneGroup(zones: [ZoneGroup(perc: 0.6), ZoneGroup(perc: 0.4)]),
        ZoneGroup(
            zones: [ZoneGroup(perc: 0.4), ZoneGroup(perc: 0.6)],
            horizontal: false),
        ZoneGroup(zones: [
          ZoneGroup(perc: 0.2),
          ZoneGroup(perc: 0.6),
          ZoneGroup(perc: 0.2)
        ]),
        ZoneGroup(zones: [
          ZoneGroup(perc: 0.5, horizontal: false, zones: [
            ZoneGroup(perc: 0.5),
            ZoneGroup(perc: 0.5),
          ]),
          ZoneGroup(perc: 0.5, horizontal: false, zones: [
            ZoneGroup(perc: 0.5),
            ZoneGroup(perc: 0.5),
          ]),
        ]),
        ZoneGroup(zones: [
          ZoneGroup(perc: 0.3, horizontal: false, zones: [
            ZoneGroup(perc: 0.5),
            ZoneGroup(perc: 0.5),
          ]),
          ZoneGroup(perc: 0.4),
          ZoneGroup(perc: 0.3, horizontal: false, zones: [
            ZoneGroup(perc: 0.5),
            ZoneGroup(perc: 0.5),
          ]),
        ]),
      ];
}
