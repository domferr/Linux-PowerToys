class Tile {
  double x;
  double y;
  double width;
  double height;
  List<int> groups;

  Tile({ required this.x, required this.y, required this.width, required this.height, this.groups = const [] });

  factory Tile.fromJson(Map<String, dynamic> json) {
    return Tile(
      x: double.parse(json['x'].toString()),
      y: double.parse(json['y'].toString()),
      width: double.parse(json['width'].toString()),
      height: double.parse(json['height'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'groups': groups
  };
}
