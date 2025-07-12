class Lane {
  final int id;
  final String laneId;

  Lane({
    required this.id,
    required this.laneId,
  });

  factory Lane.fromJson(Map<String, dynamic> json) {
    return Lane(
      id: json['id'],
      laneId: json['lane_id'],
    );
  }
}
