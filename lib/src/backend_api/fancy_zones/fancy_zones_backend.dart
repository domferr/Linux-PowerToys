import 'package:linuxpowertoys/src/backend_api/fancy_zones/zone_group.dart';
import 'package:linuxpowertoys/src/backend_api/utility_backend.dart';

/// Abstract class representing the backend for the "FancyZones" utility.
abstract class FancyZonesBackend extends UtilityBackend {
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

  /// get the layouts
  List<ZoneGroup> get layouts => [
    ZoneGroup(zones: [ZoneGroup(perc: 0.4), ZoneGroup(perc: 0.6)]),
    ZoneGroup(zones: [ZoneGroup(perc: 0.6), ZoneGroup(perc: 0.4)]),
    ZoneGroup(zones: [ZoneGroup(perc: 0.4), ZoneGroup(perc: 0.6)], horizontal: false),
    ZoneGroup(zones: [
      ZoneGroup(perc: 0.25),
      ZoneGroup(perc: 0.5),
      ZoneGroup(perc: 0.25)
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
    ZoneGroup(
        zones: [
          ZoneGroup(perc: 0.3, horizontal: false, zones: [
            ZoneGroup(perc: 0.5),
            ZoneGroup(perc: 0.5),
          ]),
          ZoneGroup(perc: 0.4),
          ZoneGroup(perc: 0.3, horizontal: false, zones: [
            ZoneGroup(perc: 0.5),
            ZoneGroup(perc: 0.5),
          ]),
        ]
    ),
  ];

  Stream<int> get selectedLayoutIndex;
  
  int get lastSelectedLayoutIndex;
  
  void selectLayout(int newIndex);
}