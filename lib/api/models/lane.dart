class Lane {
  final int id;
  final int roadwayId;
  final String laneId;

  Lane({
    required this.id,
    required this.roadwayId,
    required this.laneId,
  });

  factory Lane.fromJson(Map<String, dynamic> json) {
    return Lane(
      id: json['id'],
      roadwayId: json['roadway_id'],
      laneId: json['lane_id'],
    );
  }
}
