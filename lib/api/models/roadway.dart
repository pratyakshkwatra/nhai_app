class Roadway {
  final int id;
  final String roadwayId;
  final String name;
  final String? imagePath;

  Roadway({
    required this.id,
    required this.roadwayId,
    required this.name,
    this.imagePath,
  });

  factory Roadway.fromJson(Map<String, dynamic> json) {
    print(json);
    return Roadway(
      id: json['id'],
      roadwayId: json['roadway_id'],
      name: json['name'],
      imagePath: json['image_path'],
    );
  }
}
