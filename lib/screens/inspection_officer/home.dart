import 'package:auto_size_text/auto_size_text.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/models/survey.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nhai_app/screens/auth/login.dart';
import 'package:nhai_app/screens/survey_vehicle_data_screen.dart';
import 'package:nhai_app/services/auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class InspectionHome extends StatefulWidget {
  final AuthService authService;
  final User user;
  const InspectionHome(
      {super.key, required this.authService, required this.user});

  @override
  State<InspectionHome> createState() => _InspectionHomeState();
}

const List<String> roadWays = [];
List<Survey> surveys = [
  Survey(
    roadway: "NH148N",
    date: "10/03/2025",
    lane: "L2",
    csvPath: "assets/L2.csv",
    videoPath: "assets/L2_1080p.mp4",
    imagePath: 'assets/images/L2.jpg',
  ),
  Survey(
    roadway: "NH148N",
    date: "10/03/2025",
    lane: "R2",
    csvPath: "assets/R2.csv",
    videoPath: "assets/R2_1080p.mp4",
    imagePath: 'assets/images/R2.jpg',
  ),
];

class _InspectionHomeState extends State<InspectionHome> {
  int? viewIndex;

  Future<List<List<dynamic>>> loadCsvData(String csvPath) async {
    final rawData = await rootBundle.loadString(csvPath);
    final listData = const CsvToListConverter().convert(rawData, eol: '\n');
    listData.removeAt(0);
    return listData;
  }

  double calculateTotalDistance(List<List<double>> points) {
    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      totalDistance +=
          Geolocator.distanceBetween(start[0], start[1], end[0], end[1]);
    }
    return totalDistance / 1000;
  }

  Future<Map<String, dynamic>> loadAndProcessCSV(String csvPath) async {
    try {
      final csvData = await loadCsvData(csvPath);
      if (csvData.isEmpty) {
        return {"distance": 0.0, "road_health": 0.0};
      }

      List<List<double>> latLong = [];
      int totalValues = csvData.length;
      int totalWarnings = 0;
      int roughnessWarnings = 0;
      int rutWarnings = 0;
      int crackWarnings = 0;
      int ravellingWarnings = 0;

      for (var item in csvData) {
        if (item.length > 14) {
          final lat = double.tryParse(item[13].toString());
          final lng = double.tryParse(item[14].toString());
          if (lat != null && lng != null) latLong.add([lat, lng]);
        }
        if (item.length > 12) {
          final val5 = _tryNum(item[5]);
          final val6 = _tryNum(item[6]);
          final val7 = _tryNum(item[7]);
          final val8 = _tryNum(item[8]);
          final val9 = _tryNum(item[9]);
          final val10 = _tryNum(item[10]);
          final val11 = _tryNum(item[11]);
          final val12 = _tryNum(item[12]);

          if (val9 > val5 || val10 > val6 || val11 > val7 || val12 > val8) {
            totalWarnings++;
          }
          if (val9 > val5) roughnessWarnings++;
          if (val10 > val6) rutWarnings++;
          if (val11 > val7) crackWarnings++;
          if (val12 > val8) ravellingWarnings++;
        }
      }

      final double distance =
          latLong.length >= 2 ? calculateTotalDistance(latLong) : 0.0;
      final double roadHealth = (totalValues > 0
              ? (totalValues - totalWarnings) / totalValues
              : 0.0) *
          5;

      return {
        "distance": distance,
        "road_health": roadHealth,
        "roughness": roughnessWarnings / totalValues,
        "rut": rutWarnings / totalValues,
        "crack": crackWarnings / totalValues,
        "ravelling": ravellingWarnings / totalValues,
      };
    } catch (e) {
      return {
        "distance": 0.0,
        "road_health": 0.0,
        "error": e.toString(),
        "roughness": 0.0,
        "rut": 0.0,
        "crack": 0.0,
        "ravelling": 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> loadAndProcessMultipleCSVs(
      List<String> csvPathsRec) async {
    final List<String> csvPaths = csvPathsRec.toSet().toList();

    double totalDistance = 0.0;
    double totalRoadHealth = 0.0;
    double totalRoughness = 0.0;
    double totalRut = 0.0;
    double totalCrack = 0.0;
    double totalRavelling = 0.0;
    int fileCount = 0;

    for (String path in csvPaths) {
      final result = await loadAndProcessCSV(path);
      if (result.containsKey("error")) continue;

      totalDistance += result["distance"];
      totalRoadHealth += result["road_health"];
      totalRoughness += result["roughness"];
      totalRut += result["rut"];
      totalCrack += result["crack"];
      totalRavelling += result["ravelling"];
      fileCount++;
    }

    if (fileCount == 0) {
      return {
        "distance": 0.0,
        "road_health": 0.0,
        "roughness": 0.0,
        "rut": 0.0,
        "crack": 0.0,
        "ravelling": 0.0,
        "error": "No valid CSV files processed",
      };
    }

    return {
      "distance": totalDistance,
      "road_health": totalRoadHealth / fileCount,
      "roughness": totalRoughness / fileCount,
      "rut": totalRut / fileCount,
      "crack": totalCrack / fileCount,
      "ravelling": totalRavelling / fileCount,
      "files_processed": fileCount,
    };
  }

  double _tryNum(dynamic val) => double.tryParse(val.toString()) ?? 0.0;

  shareData(String date, double distance, double roadHealth, double roughness,
      double rut, double crack, double ravelling, Survey survey) async {
    SharePlus.instance.share(ShareParams(
        text:
            '*Survey: ${survey.roadway}-${survey.lane}*\n\n*Date*: $date\n*Distance Covered*: ${distance.toStringAsFixed(2)}\n*Road Health*: ${roadHealth.toStringAsFixed(2)}/5 ❤️\n\n*Roughness*: ${roughness.toStringAsFixed(2)}\n*Rut*: ${rut.toStringAsFixed(2)}\n*Crack*: ${crack.toStringAsFixed(2)}\n*Ravelling*: ${ravelling.toStringAsFixed(2)}'));
  }

  Widget surveyCard(Survey survey, int index) {
    final bool hasImage = survey.imagePath.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      height: MediaQuery.of(context).size.height * 0.16,
      width: double.infinity,
      decoration: BoxDecoration(
        color: hasImage ? Colors.black : Colors.red.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.asset(
                survey.imagePath,
                fit: BoxFit.cover,
                color: Colors.black.withAlpha(80),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.red.shade100,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        "${survey.roadway} - ${survey.lane}",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          shadows: const [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 5,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      FutureBuilder<Map<String, dynamic>>(
                        future: loadAndProcessCSV(survey.csvPath),
                        builder: (context, snapshot) {
                          final rating = snapshot.hasData
                              ? snapshot.data!['road_health'] ?? 0.0
                              : 0.0;

                          return RatingBarIndicator(
                            rating: rating,
                            itemBuilder: (context, _) => const Icon(
                              Icons.favorite,
                              color: Colors.redAccent,
                            ),
                            unratedColor: Colors.white.withAlpha(60),
                            itemCount: 5,
                            itemSize: 20,
                            direction: Axis.horizontal,
                          );
                        },
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (viewIndex != null) {
                        if (viewIndex == index) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SurveyVehicleDataScreen(
                                videoPath: survey.videoPath,
                                csvPath: survey.csvPath,
                                lane: survey.lane,
                                roadWay: survey.roadway,
                              ),
                            ),
                          );
                        } else {
                          setState(() => viewIndex = index);
                        }
                      } else {
                        setState(() => viewIndex = index);
                      }
                    },
                    onLongPress: () {
                      if (viewIndex == index) {
                        setState(() => viewIndex = null);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(220),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      children: [
                        AutoSizeText(
                          (viewIndex != null)
                              ? (viewIndex == index ? 'INSPECT' : 'VIEW')
                              : 'VIEW',
                          maxLines: 1,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          (viewIndex != null)
                              ? (viewIndex == index
                                  ? Icons.search
                                  : Icons.visibility)
                              : Icons.visibility,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget progressBarWithTitle(String title, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$title:",
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                LinearProgressIndicator(
                  value: value,
                  color: Colors.black.withValues(alpha: 0.6),
                  backgroundColor: Colors.red.shade100,
                  minHeight: 16,
                ),
                Text(
                  "${(value * 100).toStringAsFixed(2)}%",
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.redAccent, Colors.redAccent.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.675),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: FutureBuilder(
                    future: viewIndex != null
                        ? loadAndProcessMultipleCSVs(
                            [surveys[viewIndex!].csvPath],
                          )
                        : loadAndProcessMultipleCSVs(
                            surveys.map((s) => s.csvPath).toList(),
                          ),
                    builder: (context, asyncSnapshotMain) {
                      if (!asyncSnapshotMain.hasData) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Shimmer(
                            duration: const Duration(milliseconds: 200),
                            interval: const Duration(milliseconds: 100),
                            color: Colors.white,
                            colorOpacity: 0.6,
                            enabled: true,
                            direction: ShimmerDirection.fromLTRB(),
                            child: Container(
                              height: 140,
                              width: double.infinity,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        );
                      }

                      final data = asyncSnapshotMain.data!;
                      final distance = data["distance"];
                      final roadHealth = data["road_health"];
                      final roughness = data["roughness"];
                      final rut = data["rut"];
                      final crack = data["crack"];
                      final ravelling = data["ravelling"];

                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  viewIndex != null
                                      ? "Lane Length: ${distance.toStringAsFixed(2)} KM"
                                      : "Total Distance: ${distance.toStringAsFixed(2)} KM",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    AutoSizeText(
                                      viewIndex != null
                                          ? "Lane Health:"
                                          : "Highway Health:",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                    ),
                                    const SizedBox(width: 10),
                                    RatingBarIndicator(
                                      rating: roadHealth,
                                      itemBuilder: (context, _) => const Icon(
                                        Icons.favorite,
                                        color: Colors.redAccent,
                                      ),
                                      unratedColor:
                                          Colors.black.withValues(alpha: 0.6),
                                      itemCount: 5,
                                      itemSize: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Column(
                              children: [
                                progressBarWithTitle("Roughness", roughness),
                                const SizedBox(height: 8),
                                progressBarWithTitle("Rut", rut),
                                const SizedBox(height: 8),
                                progressBarWithTitle("Crack", crack),
                                const SizedBox(height: 8),
                                progressBarWithTitle("Ravelling", ravelling),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            height: MediaQuery.of(context).size.height * 0.675,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.0125,
                    right: MediaQuery.of(context).size.width * 0.0375,
                    left: MediaQuery.of(context).size.width * 0.0375,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                "NHAI ",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "VISION",
                                style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () async {
                              await widget.authService.logout().then((value) {
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return LoginScreen(
                                          authService: widget.authService,
                                        );
                                      },
                                    ),
                                  );
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.redAccent,
                              ),
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.logout,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.025,
                      ),
                      Expanded(
                        child: ListView.builder(
                          physics: BouncingScrollPhysics(),
                          itemCount: surveys.length,
                          itemBuilder: (context, index) {
                            Survey survey = surveys[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.width * 0.0375,
                              ),
                              child: surveyCard(survey, index),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
