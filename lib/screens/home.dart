<<<<<<< HEAD
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
import 'package:shimmer_animation/shimmer_animation.dart';
=======
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:nhai_app/screens/survey_vehicle_data_screen.dart';
>>>>>>> f51d3d2 (before changes)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

<<<<<<< HEAD
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
=======
const Map<String, List<Map<String, List<String>>>> dropDownData = {
  'NH148N': [
    {
      '10/03/2025': ['Lane L2', 'Lane R2']
    },
  ],
};

Widget dropDownMenu(BuildContext context, String header, List<String> items,
    String selectedItem, Function(dynamic) onChanged) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding:
            EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05),
        child: Text(
          header,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
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
      const SizedBox(height: 16),
    ],
  );
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedRoad = dropDownData.keys.first;
  String selectedDate = '';
  String selectedLane = '';

  List<String> getDatesForSelectedRoad() {
    final listOfMaps = dropDownData[selectedRoad]!;
    return listOfMaps.map((map) => map.keys.first).toList();
  }

  List<String> getLanesForSelectedDate() {
    final listOfMaps = dropDownData[selectedRoad]!;
    for (var map in listOfMaps) {
      if (map.containsKey(selectedDate)) {
        return map[selectedDate]!;
      }
    }
    return [];
  }
>>>>>>> f51d3d2 (before changes)

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
  }

  Widget dropDownMenu(BuildContext context, String header, List<String> items,
      String selectedItem, Function(dynamic) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05),
          child: Text(
            header,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
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
=======
    selectedDate = getDatesForSelectedRoad().first;
    selectedLane = getLanesForSelectedDate().first;
>>>>>>> f51d3d2 (before changes)
  }

  double calculateTotalDistance(List<List<double>> points) {
    double totalDistance = 0;

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      final distance = Geolocator.distanceBetween(
        start[0],
        start[1],
        end[0],
        end[1],
      );

      totalDistance += distance;
    }

    return totalDistance / 1000;
  }

  Future<Map<String, dynamic>> loadAndProcessCSV(String csvPath) async {
    try {
      List<List<dynamic>> csvData = await loadCsvData(csvPath);

      if (csvData.isEmpty) {
        return {
          "distance": 0.0,
          "road_health": 0.0,
        };
      }

      List<List<double>> latLong = [];
      int totalValues = csvData.length;
      int totalWarnings = 0;

      int roughnessWarnings = 0;
      int rutWarnings = 0;
      int crackWarnings = 0;
      int ravellingWarnings = 0;

      for (List item in csvData) {
        if (item.length > 14) {
          final lat = double.tryParse(item[13].toString());
          final lng = double.tryParse(item[14].toString());

          if (lat != null && lng != null) {
            latLong.add([lat, lng]);
          }
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
            totalWarnings += 1;
          }

          if (val9 > val5) {
            roughnessWarnings += 1;
          }
          if (val10 > val6) {
            rutWarnings += 1;
          }
          if (val11 > val7) {
            crackWarnings += 1;
          }
          if (val12 > val7) {
            ravellingWarnings += 1;
          }
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
        "roughness": double.parse((roughnessWarnings / totalValues).toString()),
        "rut": double.parse((rutWarnings / totalValues).toString()),
        "crack": double.parse((crackWarnings / totalValues).toString()),
        "ravelling": double.parse((ravellingWarnings / totalValues).toString()),
      };
    } catch (e) {
      return {
        "distance": 0.0,
        "road_health": 0.0,
        "error": e.toString(),
        "roughness": 0,
        "rut": 0,
        "crack": 0,
        "ravelling": 0,
      };
    }
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
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                LinearProgressIndicator(
                  value: value,
                  color: Colors.redAccent,
                  backgroundColor: Colors.grey.shade300,
                  minHeight: 16,
                ),
                Text(
                  "${(value * 100).toStringAsFixed(2)}%",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  exportData(String date, double distance, double roadHealth, double roughness, double rut, double crack, double ravelling) {

  }

  @override
  Widget build(BuildContext context) {
    final dates = getDatesForSelectedRoad();
    final lanes = getLanesForSelectedDate();

    return Scaffold(
<<<<<<< HEAD
      backgroundColor: Colors.white,
=======
>>>>>>> f51d3d2 (before changes)
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text(
          "NHAI Inspection App",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
<<<<<<< HEAD
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.025,
              ),
              dropDownMenu(context, "Select Highway: ", roadWays, roadWays[0],
                  (dynamic value) {
                setState(() {
                  selectedRoadway = value;
                });
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Builder(builder: (context) {
                  List<Survey> surveysValid = surveys.where((survey) {
                    if (survey.roadway == selectedRoadway) {
                      return true;
                    } else {
                      return false;
                    }
                  }).toList();

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
                            trailing: Icon(
                              Icons.arrow_downward,
                            ),
                            tileColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: Text(
                              "Survey: ${survey.roadway} - ${survey.lane}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                            ),
                            children: [
                              SizedBox(
                                height: 8,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Date: ${survey.date}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    FutureBuilder(
                                        future:
                                            loadAndProcessCSV(survey.csvPath),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            double distance =
                                                snapshot.data!["distance"];
                                            double roadHealth =
                                                snapshot.data!["road_health"];
                                            double roughness =
                                                snapshot.data!["roughness"];
                                            double rut = snapshot.data!["rut"];
                                            double crack =
                                                snapshot.data!["crack"];
                                            double ravelling =
                                                snapshot.data!["ravelling"];

                                            return SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.9,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Distance Covered: ${distance.toStringAsFixed(2)}KM",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 8,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Road Health:",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 8,
                                                      ),
                                                      RatingBar.builder(
                                                        initialRating:
                                                            roadHealth,
                                                        minRating: 0,
                                                        direction:
                                                            Axis.horizontal,
                                                        allowHalfRating: true,
                                                        itemCount: 5,
                                                        itemSize: 18,
                                                        itemPadding: EdgeInsets
                                                            .symmetric(
                                                          horizontal: 1.0,
                                                        ),
                                                        itemBuilder:
                                                            (context, _) =>
                                                                Icon(
                                                          Icons.favorite,
                                                          color:
                                                              Colors.redAccent,
                                                          size: 8,
                                                        ),
                                                        ignoreGestures: true,
                                                        onRatingUpdate:
                                                            (rating) {},
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 8,
                                                  ),
                                                  Divider(),
                                                  SizedBox(
                                                    height: 8,
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.85,
                                                    child: progressBarWithTitle(
                                                      "Roughness",
                                                      roughness,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.85,
                                                    child: progressBarWithTitle(
                                                      "Rut",
                                                      rut,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.85,
                                                    child: progressBarWithTitle(
                                                      "Crack",
                                                      crack,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.85,
                                                    child: progressBarWithTitle(
                                                      "Ravelling",
                                                      ravelling,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 8,
                                                  ),
                                                  SizedBox(
                                                    height: 8,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.4,
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            exportData(survey.date, distance, roadHealth, roughness, rut, crack, ravelling);
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .redAccent,
                                                            foregroundColor:
                                                                Colors.white,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        18,
                                                                    vertical:
                                                                        4),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            elevation: 4,
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceEvenly,
                                                            children: [
                                                              Icon(
                                                                Icons.ios_share,
                                                                size: 22,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                              Text(
                                                                'EXPORT',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.4,
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) {
                                                              return SurveyVehicleDataScreen(
                                                                videoPath:
                                                                    'assets/${survey.lane.split(" ").last}_1080p.mp4',
                                                                csvPath:
                                                                    'assets/${survey.lane.split(" ").last}.csv',
                                                                lane:
                                                                    survey.lane,
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
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        18,
                                                                    vertical:
                                                                        4),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            elevation: 4,
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceEvenly,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .find_in_page,
                                                                size: 22,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              Text(
                                                                'INSPECT',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadiusGeometry.circular(
                                                      12),
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
                                        }),
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
=======
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                dropDownMenu(
                  context,
                  "Select Highway/Roadway",
                  dropDownData.keys.toList(),
                  selectedRoad,
                  (value) {
                    setState(() {
                      selectedRoad = value;
                      selectedDate = getDatesForSelectedRoad().first;
                      selectedLane = getLanesForSelectedDate().first;
                    });
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
                dropDownMenu(
                  context,
                  "Select Survey Date",
                  dates,
                  selectedDate,
                  (value) {
                    setState(() {
                      selectedDate = value;
                      selectedLane = getLanesForSelectedDate().first;
                    });
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
                dropDownMenu(
                  context,
                  "Select Survey Lane",
                  lanes,
                  selectedLane,
                  (value) {
                    setState(() {
                      selectedLane = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return SurveyVehicleDataScreen(
                      videoPath: 'assets/${selectedLane.split(" ").last}_1080p.mp4',
                      csvPath: 'assets/${selectedLane.split(" ").last}.csv',
                      lane: selectedLane,
                    );
                  }));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Submit',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
>>>>>>> f51d3d2 (before changes)
        ),
      ),
    );
  }
}
