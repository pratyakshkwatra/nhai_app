import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:nhai_app/models/survey.dart';
import 'package:nhai_app/screens/survey_vehicle_data_screen.dart';
import 'package:rounded_expansion_tile/rounded_expansion_tile.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const List<String> roadWays = ["NH148N"];
List<Survey> surveys = [
  Survey(
    roadway: "NH148N",
    date: "10/03/2025",
    lane: "L2",
    csvPath: "assets/L2.csv",
    videoPath: "assets/L2_1080p.mp4",
  ),
  Survey(
    roadway: "NH148N",
    date: "10/03/2025",
    lane: "R2",
    csvPath: "assets/R2.csv",
    videoPath: "assets/R2_1080p.mp4",
  ),
];

class _HomeScreenState extends State<HomeScreen> {
  String selectedRoadway = roadWays[0];

  Widget dropDownMenu(BuildContext context, String header, List<String> items,
      String selectedItem, Function(dynamic) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05),
          child: Text(header,
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: CustomDropdown<String>(
                items: items,
                initialItem: selectedItem,
                onChanged: onChanged,
                decoration: CustomDropdownDecoration(
                  closedFillColor: Colors.grey.shade300,
                  closedBorderRadius: BorderRadius.circular(12),
                  expandedFillColor: Colors.grey.shade300,
                  expandedBorderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

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

  double _tryNum(dynamic val) => double.tryParse(val.toString()) ?? 0.0;

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
                  color: Colors.redAccent,
                  backgroundColor: Colors.grey.shade300,
                  minHeight: 16,
                ),
                Text("${(value * 100).toStringAsFixed(2)}%",
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w300)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  shareData(String date, double distance, double roadHealth, double roughness,
      double rut, double crack, double ravelling, Survey survey) async {
    SharePlus.instance.share(ShareParams(
        text:
            '*Survey: ${survey.roadway}-${survey.lane}*\n\n*Date*: $date\n*Distance Covered*: ${distance.toStringAsFixed(2)}\n*Road Health*: ${roadHealth.toStringAsFixed(2)}/5 ❤️\n\n*Roughness*: ${roughness.toStringAsFixed(2)}\n*Rut*: ${rut.toStringAsFixed(2)}\n*Crack*: ${crack.toStringAsFixed(2)}\n*Ravelling*: ${ravelling.toStringAsFixed(2)}'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text("NHAI VISION",
            style:
                GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              dropDownMenu(
                  context, "Select Highway: ", roadWays, selectedRoadway,
                  (dynamic value) {
                setState(() => selectedRoadway = value);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Builder(builder: (context) {
                  List<Survey> surveysValid = surveys
                      .where((s) => s.roadway == selectedRoadway)
                      .toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: surveysValid.length,
                    itemBuilder: (context, index) {
                      Survey survey = surveysValid[index];
                      return Padding(
                        padding:
                            const EdgeInsets.only(top: 16, left: 8, right: 8),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: RoundedExpansionTile(
                            trailing: Icon(Icons.arrow_downward),
                            tileColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: Text(
                                "Survey: ${survey.roadway} - ${survey.lane}",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, fontSize: 20)),
                            children: [
                              SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Date: ${survey.date}",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    SizedBox(height: 8),
                                    FutureBuilder(
                                      future: loadAndProcessCSV(survey.csvPath),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          final data = snapshot.data!;
                                          final distance = data["distance"];
                                          final roadHealth =
                                              data["road_health"];
                                          final roughness = data["roughness"];
                                          final rut = data["rut"];
                                          final crack = data["crack"];
                                          final ravelling = data["ravelling"];

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  "Distance Covered: ${distance.toStringAsFixed(2)}KM",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Text("Road Health:",
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                  SizedBox(width: 8),
                                                  RatingBarIndicator(
                                                    rating: roadHealth,
                                                    itemBuilder: (context, _) =>
                                                        Icon(Icons.favorite,
                                                            color: Colors
                                                                .redAccent),
                                                    itemCount: 5,
                                                    itemSize: 18,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Divider(),
                                              SizedBox(height: 8),
                                              progressBarWithTitle(
                                                  "Roughness", roughness),
                                              progressBarWithTitle("Rut", rut),
                                              progressBarWithTitle(
                                                  "Crack", crack),
                                              progressBarWithTitle(
                                                  "Ravelling", ravelling),
                                              SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      shareData(
                                                          survey.date,
                                                          distance,
                                                          roadHealth,
                                                          roughness,
                                                          rut,
                                                          crack,
                                                          ravelling,
                                                          survey);
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.redAccent,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 18,
                                                              vertical: 4),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12)),
                                                      elevation: 4,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Icon(Icons.ios_share,
                                                            size: 22,
                                                            color:
                                                                Colors.black),
                                                        Text('SHARE',
                                                            style: GoogleFonts.poppins(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                      ],
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(context,
                                                          MaterialPageRoute(
                                                              builder:
                                                                  (context) {
                                                        return SurveyVehicleDataScreen(
                                                          videoPath:
                                                              survey.videoPath,
                                                          csvPath:
                                                              survey.csvPath,
                                                          lane: survey.lane,
                                                          roadWay:
                                                              survey.roadway,
                                                        );
                                                      }));
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.black,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 18,
                                                              vertical: 4),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12)),
                                                      elevation: 4,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Icon(Icons.find_in_page,
                                                            size: 22,
                                                            color:
                                                                Colors.white),
                                                        Text('INSPECT',
                                                            style: GoogleFonts.poppins(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        } else {
                                          return ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Shimmer(
                                              duration:
                                                  Duration(milliseconds: 200),
                                              interval:
                                                  Duration(milliseconds: 100),
                                              color: Colors.grey.shade400,
                                              colorOpacity: 0.9,
                                              enabled: true,
                                              direction:
                                                  ShimmerDirection.fromLTRB(),
                                              child: Container(
                                                height: 128,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.9,
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
