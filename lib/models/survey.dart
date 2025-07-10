class Survey {
  final String roadway;
  final String date;
  final String lane;
  final String csvPath;
  final String videoPath;
  final String imagePath;

  Survey({
    required this.roadway,
    required this.date,
    required this.lane,
    required this.csvPath,
    required this.videoPath,
    required this.imagePath,
  });
}
