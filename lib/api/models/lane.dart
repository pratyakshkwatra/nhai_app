class Lane {
  final int id;
  final String laneId;
  final DateTime createdAt;
  final LaneData? data;

  Lane({
    required this.id,
    required this.laneId,
    required this.createdAt,
    this.data,
  });

  factory Lane.fromJson(Map<String, dynamic> json) {
    return Lane(
      id: json['id'],
      laneId: json['lane_id'],
      createdAt: DateTime.parse(json['created_at']),
      data: json['data'] != null ? LaneData.fromJson(json['data']) : null,
    );
  }
}

class LaneData {
  final int id;
  final int laneId;
  final String? videoPath;
  final String? xlsxPath;
  final String processingStatus;
  final int processingPercent;
  final String statusMsg;
  final DateTime createdAt;

  LaneData({
    required this.id,
    required this.laneId,
    this.videoPath,
    this.xlsxPath,
    required this.processingStatus,
    required this.processingPercent,
    required this.statusMsg,
    required this.createdAt,
  });

  factory LaneData.fromJson(Map<String, dynamic> json) {
    return LaneData(
      id: json['id'],
      laneId: json['lane_id'],
      videoPath: json['video_path'],
      xlsxPath: json['xlsx_path'],
      processingStatus: json['processing_status'],
      processingPercent: json['processing_percent'],
      statusMsg: json['status_msg'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
