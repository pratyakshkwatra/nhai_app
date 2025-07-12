import 'package:auto_size_text/auto_size_text.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:nhai_app/api/models/lane.dart';
import 'package:nhai_app/api/models/roadway.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/api/officer_api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nhai_app/screens/auth/login.dart';
import 'package:nhai_app/screens/inspection_officer/roadways.dart';
import 'package:nhai_app/services/auth.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class InspectionHome extends StatefulWidget {
  final AuthService authService;
  final User user;
  const InspectionHome(
      {super.key, required this.authService, required this.user});

  @override
  State<InspectionHome> createState() => _InspectionHomeState();
}

class _InspectionHomeState extends State<InspectionHome> {
  List<Roadway> roadWays = [];

  Future<List<List<dynamic>>> loadCsvData(String csvUrl) async {
    final response = await http.get(Uri.parse(csvUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to load CSV from $csvUrl');
    }

    final csvRaw = response.body;
    final listData = const CsvToListConverter().convert(csvRaw, eol: '\n');
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
      List<Roadway> recRoadWays) async {
    final List<String> csvPaths = [];
    List<Roadway> roadWays = await OfficerApi().getMyRoadways();

    for (Roadway roadWay in roadWays) {
      if (recRoadWays.any((rw) => rw.id == roadWay.id) || recRoadWays.isEmpty) {
        List<Lane> lanes = await OfficerApi().getLanes(roadWay.id);
        for (Lane lane in lanes) {
          if (lane.data != null) {
            if (lane.data!.xlsxPath != null) {
              csvPaths.add(lane.data!.xlsxPath!);
            }
          }
        }
      }
    }

    double totalDistance = 0.0;
    double totalRoadHealth = 0.0;
    double totalRoughness = 0.0;
    double totalRut = 0.0;
    double totalCrack = 0.0;
    double totalRavelling = 0.0;
    int fileCount = 0;

    for (String path in csvPaths) {
      final result = await loadAndProcessCSV(path);
      if (result.containsKey("error")) {
        continue;
      }

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

  Widget progressBarWithTitle(String title, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$title:",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Container(
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.7),
                  offset: Offset(-2, -2),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: Colors.red.shade200.withValues(alpha: 0.5),
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: value),
                      duration: Duration(milliseconds: 600),
                      builder: (context, val, _) => LinearProgressIndicator(
                        value: val,
                        minHeight: 22,
                        backgroundColor: Colors.red.shade100,
                        color: Colors.redAccent.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      "${(value * 100).toStringAsFixed(2)}%",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
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
                colors: [Colors.redAccent.shade700, Colors.redAccent.shade200],
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
                    future: loadAndProcessMultipleCSVs(
                      roadWays,
                    ),
                    builder: (context, asyncSnapshotMain) {
                      if (!asyncSnapshotMain.hasData) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Shimmer(
                            color: Colors.white,
                            colorOpacity: 0.6,
                            enabled: true,
                            direction: ShimmerDirection.fromLTRB(),
                            child: Container(
                              height: 140,
                              width: double.infinity,
                              color: Colors.red.shade300,
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

                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        child: Column(
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: distance),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOut,
                              builder: (context, animatedDistance, _) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(220),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AutoSizeText(
                                        roadWays.isNotEmpty
                                            ? "Lane Length: ${animatedDistance.toStringAsFixed(2)} KM"
                                            : "Total Distance: ${animatedDistance.toStringAsFixed(2)} KM",
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
                                            roadWays.isNotEmpty
                                                ? "Lane Health:"
                                                : "Highway Health:",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                          ),
                                          const SizedBox(width: 10),
                                          TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                                begin: 0, end: roadHealth),
                                            duration: const Duration(
                                                milliseconds: 800),
                                            curve: Curves.easeOut,
                                            builder:
                                                (context, animatedRating, _) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.white
                                                          .withAlpha(180),
                                                      offset:
                                                          const Offset(-2, -2),
                                                      blurRadius: 4,
                                                    ),
                                                    BoxShadow(
                                                      color: Colors.red.shade200
                                                          .withAlpha(130),
                                                      offset:
                                                          const Offset(2, 2),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: Colors.red.shade100
                                                        .withAlpha(100),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: RatingBarIndicator(
                                                  rating: animatedRating,
                                                  itemBuilder: (context, _) =>
                                                      const Icon(
                                                    Icons.favorite,
                                                    color: Colors.redAccent,
                                                  ),
                                                  unratedColor:
                                                      Colors.red.shade200,
                                                  itemCount: 5,
                                                  itemSize: 18,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                key: ValueKey("stats_card"),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(220),
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
                                    progressBarWithTitle(
                                        "Roughness", roughness),
                                    const SizedBox(height: 8),
                                    progressBarWithTitle("Rut", rut),
                                    const SizedBox(height: 8),
                                    progressBarWithTitle("Crack", crack),
                                    const SizedBox(height: 8),
                                    progressBarWithTitle(
                                        "Ravelling", ravelling),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                color: Colors.redAccent.shade200
                                    .withValues(alpha: 0.9),
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
                      Expanded(
                        child: RoadwaysOfficer(
                          authService: widget.authService,
                          user: widget.user,
                          onView: (List<Roadway> recRoadWays) {
                            setState(() {
                              roadWays = recRoadWays;
                            });
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
