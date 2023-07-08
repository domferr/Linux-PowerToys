import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/zone_props.dart';

class ZoneGroup {
  ZoneGroup({double? perc, bool? horizontal, this.zones = const []}) {
    props = ZoneProps(perc: perc ?? 1.0, horizontal: horizontal ?? true);
  }

  late final ZoneProps props;
  List<ZoneGroup> zones;
}
