import 'package:linuxpowertoys/src/backend_api/tile.dart';
import 'package:logging/logging.dart';

class Layout {
  String id;
  List<Tile> tiles;

  Layout({ required this.id, required this.tiles });

  factory Layout.fromJson(Map<String, dynamic> json) {
    var logger = Logger('Layout');

    return Layout(
        id: json['id'] as String,
        tiles: (json['tiles'] as List).cast<Map<String, dynamic>>().map((tileJson) => Tile.fromJson(tileJson)).toList()
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tiles': tiles.map((tile) => tile.toJson()).toList(),
  };
}
