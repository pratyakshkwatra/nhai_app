import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:nhai_app/components/blinking_icon.dart';
import 'package:csv/csv.dart';
import 'package:nhai_app/components/graph.dart';
import 'package:nhai_app/components/playback_speed.dart';
import 'package:nhai_app/models/survey_frame.dart';
import 'package:nhai_app/models/warning.dart';
import 'package:nhai_app/screens/warnings.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:video_player/video_player.dart';
import 'package:latlong2/latlong.dart';

class SurveyVehicleDataScreen extends StatefulWidget {
  final String videoPath;
  final String csvPath;
  final String lane;
  final String roadWay;

  const SurveyVehicleDataScreen(
      {super.key,
      required this.videoPath,
      required this.csvPath,
      required this.lane,
      required this.roadWay});

  @override
  State<SurveyVehicleDataScreen> createState() =>
      _SurveyVehicleDataScreenState();
}

final List<LatLng> trackPoints = [];
final List<Polyline> polyLines = [];

final List<double> roughnessValues = [];
final List<double> rutValues = [];
final List<double> crackValues = [];
final List<double> areaValues = [];

final List<Warning> warnings = [];

VideoPlayerController? videoPlayerController;

ChewieController? chewieController;

Chewie? playerWidget;
late List<SurveyFrame> processedFrames;
int previousFrameIndex = 0;

class _SurveyVehicleDataScreenState extends State<SurveyVehicleDataScreen>
    with TickerProviderStateMixin {
  Duration endDuration = Duration.zero;
  bool videoPaused = true;
  late final AnimatedMapController animatedMapController;

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void initState() {
    super.initState();
    warnings.clear();
    trackPoints.clear();
    polyLines.clear();
    animatedMapController = AnimatedMapController(vsync: this);
    videoPlayerController = VideoPlayerController.asset(widget.videoPath);
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController!,
      autoPlay: false,
      looping: false,
      draggableProgressBar: false,
      showControls: true,
      aspectRatio: 0.52,
      allowMuting: false,
      allowPlaybackSpeedChanging: false,
      showOptions: false,
      allowFullScreen: true,
      customControls: Align(
        alignment: Alignment.bottomRight,
        child: GestureDetector(
          onTap: () {
            if (chewieController!.isFullScreen) {
              chewieController!.exitFullScreen();
            } else {
              chewieController!.enterFullScreen();
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );

    playerWidget = Chewie(
      controller: chewieController!,
    );

    videoPlayerController!.initialize().then((_) {
      setState(() {
        endDuration = videoPlayerController!.value.duration;
      });
    });
  }

  @override
  void dispose() {
    videoPlayerController!.dispose();
    chewieController!.dispose();
    animatedMapController.dispose();

    super.dispose();
  }

  TableRow _buildTableHeader(String col1, String col2, String col3) {
    return TableRow(
      children: [
        _headerCell(col1, isLeft: true),
        _headerCell(col2, isRight: false),
        _headerCell(col3, isRight: true),
      ],
    );
  }

  TableRow _buildTableRow(
      String rowLabel, List<double> valList, String value, String limit,
      {bool last = false}) {
    return TableRow(
      children: [
        _dataCell(
          rowLabel,
          valList,
          label: true,
          last: last,
          limit: (limit != "N.A.") ? double.parse(limit) : 0,
        ),
        _dataCell(value, []),
        _dataCell(limit, []),
      ],
    );
  }

  Widget _headerCell(String text, {bool isLeft = false, bool isRight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.only(
          topLeft: isLeft ? Radius.circular(12) : Radius.zero,
          topRight: isRight ? Radius.circular(12) : Radius.zero,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _dataCell(String text, List<double> valList,
      {bool label = false, bool last = false, double limit = 0}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: label ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: last ? Radius.circular(12) : Radius.zero,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
            ),
          ),
          if (label && valList.isNotEmpty)
            GestureDetector(
              onTap: () {
                final selectedChip = ValueNotifier<String>("10");
                List<String> chipOptions = ["10", "25", "100", "All"];

                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext context) {
                    return Dialog(
                      backgroundColor: Colors.transparent,
                      child:
                          StatefulBuilder(builder: (context, setStateWarnings) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                padding: EdgeInsets.all(8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 10),
                                        child: Row(
                                          children: [
                                            Text(
                                              "$text Graph",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: Colors.black,
                                        ),
                                        child: const CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.black,
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              valList.length == 1
                                  ? SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.30,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              "No Data Available",
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 24,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 18),
                                              child: Text(
                                                "Move forward in time using the play/pause button or the progress bar!",
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w300,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        SizedBox(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: 64,
                                          child: ValueListenableBuilder<String>(
                                              valueListenable: selectedChip,
                                              builder: (context, value, _) {
                                                return GridView.builder(
                                                  gridDelegate:
                                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 4,
                                                    crossAxisSpacing: 4,
                                                    mainAxisSpacing: 4,
                                                    childAspectRatio: 1.5,
                                                  ),
                                                  itemCount: chipOptions.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final label = index !=
                                                            (chipOptions
                                                                    .length -
                                                                1)
                                                        ? "${chipOptions[index]}u"
                                                        : chipOptions[index];
                                                    return ChoiceChip(
                                                      color: WidgetStateProperty
                                                          .resolveWith<Color?>(
                                                        (Set<WidgetState>
                                                            states) {
                                                          if (states.contains(
                                                              WidgetState
                                                                  .selected)) {
                                                            return Colors
                                                                .redAccent;
                                                          }
                                                          return Colors
                                                              .grey.shade200;
                                                        },
                                                      ),
                                                      avatar: null,
                                                      showCheckmark: false,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadiusGeometry
                                                                .circular(
                                                          18,
                                                        ),
                                                        side: BorderSide(
                                                          color: Colors
                                                              .grey.shade200,
                                                        ),
                                                      ),
                                                      label: Text(label),
                                                      selected: selectedChip
                                                              .value ==
                                                          chipOptions[index],
                                                      onSelected: (_) {
                                                        selectedChip.value =
                                                            chipOptions[index];
                                                      },
                                                    );
                                                  },
                                                );
                                              }),
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.30,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: ValueListenableBuilder<String>(
                                              valueListenable: selectedChip,
                                              builder: (context, chipValue, _) {
                                                final chartData = chipValue ==
                                                        "All"
                                                    ? valList
                                                        .asMap()
                                                        .entries
                                                        .map((entry) => {
                                                              'index':
                                                                  entry.key,
                                                              'value':
                                                                  entry.value,
                                                            })
                                                        .toList()
                                                    : valList
                                                        .asMap()
                                                        .entries
                                                        .skip(valList.length >
                                                                int.parse(
                                                                    chipValue)
                                                            ? valList.length -
                                                                int.parse(
                                                                    chipValue)
                                                            : 0)
                                                        .map((entry) => {
                                                              'index':
                                                                  entry.key,
                                                              'value':
                                                                  entry.value,
                                                            })
                                                        .toList();
                                                return ClipRRect(
                                                  borderRadius:
                                                      BorderRadiusGeometry
                                                          .circular(12),
                                                  child: CustomGraph(
                                                    data:
                                                        chartData.map((point) {
                                                      final x =
                                                          (point['index'] ?? 0)
                                                              .toDouble();
                                                      final y =
                                                          (point['value'] ?? 0)
                                                              .toDouble();
                                                      return FlSpot(x, y);
                                                    }).toList(),
                                                    limit: limit,
                                                    showSpots: (chipValue ==
                                                                "All") ||
                                                            (chipValue == "100")
                                                        ? false
                                                        : true,
                                                    average: chipValue == "All"
                                                        ? valList.isNotEmpty
                                                            ? valList.reduce((a, b) =>
                                                                    a + b) /
                                                                valList.length
                                                            : 0.0
                                                        : valList
                                                                .skip(valList.length > int.parse(chipValue)
                                                                    ? valList.length -
                                                                        int.parse(
                                                                            chipValue)
                                                                    : 0)
                                                                .reduce((a, b) =>
                                                                    a + b) /
                                                            valList
                                                                .skip(valList.length >
                                                                        int.parse(
                                                                            chipValue)
                                                                    ? valList.length -
                                                                        int.parse(chipValue)
                                                                    : 0)
                                                                .length,
                                                  ),
                                                );
                                              }),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 8, bottom: 8),
                                          child: Align(
                                            alignment: Alignment.bottomRight,
                                            child: Text(
                                              "* 1u = 100 Chn",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w300),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                            ],
                          ),
                        );
                      }),
                    );
                  },
                );
              },
              child: Icon(
                Icons.bar_chart,
              ),
            ),
        ],
      ),
    );
  }

  Future<List<List<dynamic>>> loadCsvData(String csvPath) async {
    final rawData = await rootBundle.loadString(csvPath);

    final listData = const CsvToListConverter().convert(rawData, eol: '\n');
    listData.removeAt(0);
    return listData;
  }

  Future<void> processCsv(String csvPath) async {
    List<List<dynamic>> listData = await loadCsvData(csvPath);

    processedFrames = listData.where((row) {
      return double.tryParse(row.last.toString()) != null;
    }).map((row) {
      final ts = Duration(milliseconds: int.tryParse(row.last.toString()) ?? 0);
      final lat = double.tryParse(row[13].toString());
      final lng = double.tryParse(row[14].toString());
      return SurveyFrame(
        timestamp: ts,
        position: (lat != null && lng != null) ? LatLng(lat, lng) : null,
        roughness: double.tryParse(row[9].toString()),
        rut: double.tryParse(row[10].toString()),
        crack: double.tryParse(row[11].toString()),
        area: double.tryParse(row[12].toString()),
        refRough: double.tryParse(row[5].toString()),
        refRut: double.tryParse(row[6].toString()),
        refCrack: double.tryParse(row[7].toString()),
        refArea: double.tryParse(row[8].toString()),
      );
    }).toList();
  }

  final List<String> satelliteFallbackUrls = [
    'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ];

  Future<String> getWorkingTileUrl(List<String> urls) async {
    for (final url in urls) {
      final testUrl = url
          .replaceAll('{z}', '1')
          .replaceAll('{x}', '1')
          .replaceAll('{y}', '1');
      try {
        final res =
            await http.get(Uri.parse(testUrl)).timeout(Duration(seconds: 2));
        if (res.statusCode == 200) return url;
      } catch (_) {}
    }
    return urls.last;
  }

  @override
  Widget build(BuildContext context) {
    final tileProvider = FMTCTileProvider(
      stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
    );

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            bottom: true,
            child: FutureBuilder<void>(
                future: processCsv(widget.csvPath),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  return ValueListenableBuilder(
                    valueListenable: videoPlayerController!,
                    builder: (context, value, _) {
                      final position = value.position;
                      final duration = value.duration;

                      final List<SurveyFrame> frames = processedFrames;
                      if (frames.isEmpty) {
                        return const Text("No data available");
                      }

                      int currentFrameIndex =
                          frames.indexWhere((f) => f.timestamp >= position);
                      if (currentFrameIndex == -1) {
                        currentFrameIndex = frames.length - 1;
                      }

                      if (currentFrameIndex < previousFrameIndex) {
                        trackPoints.clear();
                        polyLines.clear();
                        roughnessValues.clear();
                        rutValues.clear();
                        crackValues.clear();
                        areaValues.clear();
                        warnings.clear();
                        previousFrameIndex = 0;
                      }

                      for (int i = previousFrameIndex;
                          i <= currentFrameIndex;
                          i++) {
                        final frame = frames[i];

                        if (frame.position != null) {
                          trackPoints.add(frame.position!);

                          if (trackPoints.length >= 2) {
                            polyLines.add(
                              Polyline(
                                strokeWidth: 16,
                                color: (frame.area != null &&
                                        frame.refArea != null &&
                                        frame.area! > frame.refArea!)
                                    ? Colors.redAccent.shade200
                                    : Colors.black,
                                points: [
                                  trackPoints[trackPoints.length - 2],
                                  trackPoints.last,
                                ],
                              ),
                            );
                          }

                          if (i == currentFrameIndex) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Timer(Duration(seconds: 2), () {
                                try {
                                  animatedMapController.animateTo(
                                    dest: frame.position!,
                                    zoom: 15.0,
                                    duration: Duration(
                                      milliseconds: (500 /
                                              videoPlayerController!
                                                  .value.playbackSpeed)
                                          .round(),
                                    ),
                                    curve: Curves.easeInSine,
                                  );
                                } catch (_) {
                                }
                              });
                            });
                          }
                        }

                        if (frame.roughness != null) {
                          roughnessValues.add(frame.roughness!);
                        }
                        if (frame.rut != null) rutValues.add(frame.rut!);
                        if (frame.crack != null) crackValues.add(frame.crack!);
                        if (frame.area != null) areaValues.add(frame.area!);

                        void addWarning(ValType type, double? ref,
                            double? value, String message) {
                          if (ref != null && value != null && value > ref) {
                            final warning = Warning(
                              type,
                              ref,
                              value,
                              message,
                              frame.timestamp,
                              false,
                              frame.position ?? const LatLng(0, 0),
                            );
                            if (!warnings.contains(warning)) {
                              warnings.add(warning);
                            }
                          }
                        }

                        addWarning(ValType.ravelling, frame.refArea, frame.area,
                            "Abnormal lane ravelling/area value detected!");
                        addWarning(ValType.crack, frame.refCrack, frame.crack,
                            "Abnormal lane crack value detected!");
                        addWarning(ValType.rut, frame.refRut, frame.rut,
                            "Abnormal lane rut value detected!");
                        addWarning(
                            ValType.roughness,
                            frame.refRough,
                            frame.roughness,
                            "Abnormal lane roughness value detected!");
                      }

                      previousFrameIndex = currentFrameIndex;

                      if (position == duration) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          videoPlayerController!.pause();
                          if (mounted && !videoPaused) {
                            setState(() {
                              videoPaused = true;
                            });
                          }
                        });
                      }

                      final frame = frames[currentFrameIndex];

                      return StatefulBuilder(builder: (context, setstateInner) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.05,
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                          child: Icon(
                                            Icons.arrow_back_ios,
                                            size: 24,
                                          ),
                                        ),
                                        Text(
                                          "Lane ${widget.lane}",
                                          style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        videoPlayerController!.pause();
                                        Navigator.push(context,
                                            MaterialPageRoute(builder:
                                                (BuildContext context) {
                                          return WarningsPage(
                                            warnings: warnings,
                                            videoPath: widget.videoPath,
                                            surveyName:
                                                "${widget.roadWay}-${widget.lane}",
                                          );
                                        }));
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 12),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.warning,
                                                    color: Colors.black,
                                                    size: 26,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      "Warnings",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Positioned(
                                                top: -16,
                                                left: -20,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(
                                                          minWidth: 24,
                                                          minHeight: 24),
                                                ),
                                              ),
                                              Positioned(
                                                top: -17,
                                                left: -16,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(
                                                          minWidth: 16,
                                                          minHeight: 16),
                                                  child: Center(
                                                    child: Text(
                                                      warnings
                                                          .where((warning) =>
                                                              !warning
                                                                  .checkedOff)
                                                          .length
                                                          .toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.40,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.45,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Stack(
                                              alignment: Alignment.bottomRight,
                                              children: [
                                                playerWidget!,
                                              ],
                                            )),
                                      ),
                                      Container(
                                        clipBehavior: Clip.antiAlias,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.40,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.45,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        child: FutureBuilder<String>(
                                            future: getWorkingTileUrl(
                                                satelliteFallbackUrls),
                                            builder: (context, asyncSnapshot) {
                                              if (!asyncSnapshot.hasData) {
                                                return Shimmer(
                                                  color: Colors.white,
                                                  colorOpacity: 0.75,
                                                  child: Container(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                );
                                              }
                                              return FlutterMap(
                                                mapController:
                                                    animatedMapController
                                                        .mapController,
                                                options: MapOptions(
                                                  initialCenter: trackPoints
                                                          .isEmpty
                                                      ? LatLng(
                                                          26.36114, 76.25048)
                                                      : trackPoints.last,
                                                  minZoom: 1,
                                                  maxZoom: 18,
                                                  initialZoom: 18,
                                                  interactionOptions:
                                                      InteractionOptions(
                                                    flags: InteractiveFlag.all,
                                                  ),
                                                ),
                                                children: [
                                                  TileLayer(
                                                    urlTemplate:
                                                        asyncSnapshot.data,
                                                    userAgentPackageName:
                                                        'com.example.nhai_app',
                                                    subdomains: ["a", "b", "c"],
                                                    tileProvider: tileProvider,
                                                  ),
                                                  PolylineLayer(
                                                    polylines: polyLines,
                                                  ),
                                                  MarkerLayer(
                                                    markers: [
                                                      if (trackPoints
                                                          .isNotEmpty)
                                                        Marker(
                                                          point:
                                                              trackPoints.last,
                                                          width: 64,
                                                          height: 64,
                                                          rotate: true,
                                                          child: Image.asset(
                                                              'assets/map_car.png'),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            }),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(4),
                                      1: FlexColumnWidth(3),
                                      2: FlexColumnWidth(3),
                                    },
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    children: [
                                      _buildTableHeader(
                                          'Type', 'Value', 'Limit'),
                                      _buildTableRow(
                                        'Chn',
                                        [],
                                        frame.timestamp.inMilliseconds
                                            .toString(),
                                        'N.A.',
                                      ),
                                      _buildTableRow(
                                        'Roughness',
                                        roughnessValues,
                                        (frame.roughness != null &&
                                                frame.refRough != null)
                                            ? '${frame.roughness!.toStringAsFixed(2)} ${(frame.roughness! > frame.refRough!) ? '❌' : '✅'}'
                                            : 'N.A.',
                                        frame.refRough?.toStringAsFixed(2) ??
                                            'N.A.',
                                      ),
                                      _buildTableRow(
                                        'Rut Depth',
                                        rutValues,
                                        (frame.rut != null &&
                                                frame.refRut != null)
                                            ? '${frame.rut!.toStringAsFixed(2)} ${(frame.rut! > frame.refRut!) ? '❌' : '✅'}'
                                            : 'N.A.',
                                        frame.refRut?.toStringAsFixed(2) ??
                                            'N.A.',
                                      ),
                                      _buildTableRow(
                                        'Crack Area',
                                        crackValues,
                                        (frame.crack != null &&
                                                frame.refCrack != null)
                                            ? '${frame.crack!.toStringAsFixed(2)} ${(frame.crack! > frame.refCrack!) ? '❌' : '✅'}'
                                            : 'N.A.',
                                        frame.refCrack?.toStringAsFixed(2) ??
                                            'N.A.',
                                      ),
                                      _buildTableRow(
                                        'Lane Area',
                                        areaValues,
                                        (frame.area != null &&
                                                frame.refArea != null)
                                            ? '${frame.area!.toStringAsFixed(2)} ${(frame.area! > frame.refArea!) ? '❌' : '✅'}'
                                            : 'N.A.',
                                        frame.refArea?.toStringAsFixed(2) ??
                                            'N.A.',
                                        last: true,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.115,
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.00625,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              formatDuration(position),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: SliderTheme(
                                                data: SliderTheme.of(context)
                                                    .copyWith(
                                                  trackHeight: 6,
                                                  inactiveTrackColor:
                                                      Colors.grey.shade200,
                                                  activeTrackColor:
                                                      Colors.redAccent,
                                                  thumbColor: Colors.redAccent,
                                                  overlayColor:
                                                      Colors.redAccent,
                                                  thumbShape:
                                                      RoundSliderThumbShape(
                                                          enabledThumbRadius:
                                                              6),
                                                  overlayShape:
                                                      RoundSliderOverlayShape(
                                                          overlayRadius: 12),
                                                ),
                                                child: Slider(
                                                  min: 0,
                                                  max: duration.inSeconds
                                                      .toDouble()
                                                      .clamp(
                                                          1, double.infinity),
                                                  value: position.inSeconds
                                                      .clamp(
                                                          0, duration.inSeconds)
                                                      .toDouble(),
                                                  onChanged: (value) {
                                                    final newDuration =
                                                        Duration(
                                                            seconds:
                                                                value.toInt());
                                                    videoPlayerController!
                                                        .seekTo(newDuration);
                                                  },
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              formatDuration(duration),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.0125,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: SizedBox(),
                                        ),
                                        Expanded(
                                          flex: 5,
                                          child: PlaybackSpeedSelector(
                                            controller: videoPlayerController!,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: SizedBox(),
                                        ),
                                        VerticalDivider(
                                          color: Colors.grey.shade300,
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: SizedBox(),
                                        ),
                                        Expanded(
                                          flex: 10,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.lightImpact();
                                                  videoPlayerController!.seekTo(
                                                    (videoPlayerController!
                                                                .value
                                                                .position
                                                                .inSeconds) >
                                                            10
                                                        ? videoPlayerController!
                                                                .value
                                                                .position -
                                                            Duration(
                                                                seconds: 10)
                                                        : Duration(seconds: 0),
                                                  );
                                                },
                                                child: Icon(
                                                  Icons.fast_rewind,
                                                  size: 32,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.mediumImpact();
                                                  if (videoPaused) {
                                                    setstateInner(() {
                                                      videoPaused = false;
                                                    });
                                                    videoPlayerController!
                                                        .play();
                                                  } else {
                                                    setstateInner(() {
                                                      videoPaused = true;
                                                    });
                                                    videoPlayerController!
                                                        .pause();
                                                  }
                                                },
                                                child: Icon(
                                                  videoPaused
                                                      ? Icons.play_arrow
                                                      : Icons.pause,
                                                  size: 32,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.lightImpact();
                                                  videoPlayerController!.seekTo(
                                                    (videoPlayerController!
                                                                    .value
                                                                    .position
                                                                    .inSeconds +
                                                                10) <
                                                            videoPlayerController!
                                                                .value
                                                                .duration
                                                                .inSeconds
                                                        ? videoPlayerController!
                                                                .value
                                                                .position +
                                                            Duration(
                                                                seconds: 10)
                                                        : videoPlayerController!
                                                            .value.duration,
                                                  );
                                                },
                                                child: Icon(
                                                  Icons.fast_forward,
                                                  size: 32,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: SizedBox(),
                                        ),
                                        VerticalDivider(
                                          color: Colors.grey.shade300,
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: SizedBox(),
                                        ),
                                        Expanded(
                                          flex: 5,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              BlinkingIcon(),
                                              SizedBox(
                                                width: 6,
                                              ),
                                              Text(
                                                "Live",
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: SizedBox(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      });
                    },
                  );
                })));
  }
}
