import 'package:flutter/material.dart';
import 'package:linuxpowertoys/src/backend_api/utilities/fancy_zones/zone_props.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ZoneWidget');

class ZoneWidget extends StatelessWidget {
  const ZoneWidget({
    super.key,
    required this.props,
    this.onTap,
    this.onSecondaryTap,
    this.padding = 0,
    this.child,
  });

  final ZoneProps props;

  final double padding;
  final void Function()? onTap;
  final void Function()? onSecondaryTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    _logger.finest("build() ZoneWidget");

    var ink = Ink(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: child,
    );

    return Expanded(
      flex: props.perc.round(),
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
