import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphic/graphic.dart';
import 'package:nhai_app/components/blinking_icon.dart';
import 'package:csv/csv.dart';
import 'package:nhai_app/components/playback_speed.dart';
import 'package:nhai_app/models/warning.dart';
import 'package:video_player/video_player.dart';
import 'package:latlong2/latlong.dart';

class SurveyVehicleDataScreen extends StatefulWidget {
  final String videoPath;
  final String csvPath;
  final String lane;

  const SurveyVehicleDataScreen(
      {super.key,
      required this.videoPath,
      required this.csvPath,
      required this.lane});

  @override
  State<SurveyVehicleDataScreen> createState() =>
      _SurveyVehicleDataScreenState();
}

final List<LatLng> trackPoints = [];

final List<double> roughnessValues = [];
final List<double> rutValues = [];
final List<double> crackValues = [];
final List<double> areaValues = [];

final List<Warning> warnings = [];

VideoPlayerController? videoPlayerController;

ChewieController? chewieController;

Chewie? playerWidget;

class _SurveyVehicleDataScreenState extends State<SurveyVehicleDataScreen> {
  Duration endDuration = Duration.zero;
  bool videoPaused = true;

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
                color: Colors.white54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fullscreen,
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
        _dataCell(rowLabel, valList, label: true, last: last),
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
      {bool label = false, bool last = false}) {
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
                      insetPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 48),
                      child:
                          StatefulBuilder(builder: (context, setStateDialog) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
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
                                    child: const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.black,
                                      child: Icon(Icons.close,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              valList.length == 1
                                  ? SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.30,
                                      child: Center(
                                        child: Text(
                                          "No Data Available",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 24,
                                          ),
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
                                                return Chart(
                                                  key: ValueKey(
                                                      selectedChip.value),
                                                  data: [...chartData],
                                                  variables: {
                                                    'index': Variable(
                                                      accessor: (Map map) =>
                                                          map['index']
                                                              .toString(),
                                                      scale: OrdinalScale(),
                                                    ),
                                                    'value': Variable(
                                                        accessor: (Map map) =>
                                                            map['value']
                                                                as num),
                                                  },
                                                  marks: [
                                                    LineMark(
                                                      shape: ShapeEncode(
                                                          value: BasicLineShape(
                                                              smooth: true)),
                                                      color: ColorEncode(
                                                          value:
                                                              Colors.redAccent),
                                                      size:
                                                          SizeEncode(value: 1),
                                                    ),
                                                    PointMark(
                                                      color: ColorEncode(
                                                          value:
                                                              Colors.redAccent),
                                                      size:
                                                          SizeEncode(value: 2),
                                                    ),
                                                  ],
                                                  axes: [
                                                    AxisGuide(
                                                        dim: Dim.x,
                                                        tickLine: TickLine(
                                                            style: PaintStyle(
                                                                fillColor: Colors
                                                                    .transparent,
                                                                strokeColor: Colors
                                                                    .transparent))),
                                                    Defaults.verticalAxis,
                                                  ],
                                                  selections: {
                                                    'tap': PointSelection(
                                                      on: {GestureType.tap},
                                                      dim: Dim.x,
                                                    ),
                                                  },
                                                  tooltip: TooltipGuide(
                                                      radius:
                                                          Radius.circular(12)),
                                                );
                                              }),
                                        ),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            "* 1u = 100 Chn",
                                            style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w300),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: true,
        child: FutureBuilder<List<List<dynamic>>>(
            future: loadCsvData(widget.csvPath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return ValueListenableBuilder(
                    valueListenable: videoPlayerController!,
                    builder: (context, value, _) {
                      final position = value.position;
                      final duration = value.duration;

                      List<List<dynamic>> listData = snapshot.data ?? [];
                      int index = 0;

                      trackPoints.clear();
                      roughnessValues.clear();
                      rutValues.clear();
                      crackValues.clear();
                      areaValues.clear();

                      for (List item in listData) {
                        if (double.tryParse(item.last.toString()) != null) {
                          if (item.last == position.inMilliseconds ||
                              item.last > position.inMilliseconds) {
                            index = listData.indexOf(item);

                            final lat =
                                double.tryParse(listData[index][13].toString());
                            final lng =
                                double.tryParse(listData[index][14].toString());
                            final rough =
                                double.tryParse(listData[index][9].toString());
                            final rut =
                                double.tryParse(listData[index][10].toString());
                            final crack =
                                double.tryParse(listData[index][11].toString());
                            final area =
                                double.tryParse(listData[index][12].toString());

                            final refRough =
                                double.tryParse(listData[index][5].toString());
                            final refRut =
                                double.tryParse(listData[index][6].toString());
                            final refCrack =
                                double.tryParse(listData[index][7].toString());
                            final refArea =
                                double.tryParse(listData[index][8].toString());

                            if (lat != null && lng != null) {
                              trackPoints.add(LatLng(lat, lng));
                            }

                            if (rough != null) roughnessValues.add(rough);
                            if (rut != null) rutValues.add(rut);
                            if (crack != null) crackValues.add(crack);
                            if (area != null) areaValues.add(area);

                            if (area != null &&
                                refArea != null &&
                                area > refArea) {
                              Warning warning = Warning(
                                ValType.ravelling,
                                refArea,
                                area,
                                "Abnormal lane ravelling/area value detected!",
                                Duration(milliseconds: item.last),
                                false,
                              );
                              if (!warnings.contains(warning)) {
                                warnings.add(warning);
                              }
                            }

                            if (crack != null &&
                                refCrack != null &&
                                crack > refCrack) {
                              Warning warning = Warning(
                                ValType.crack,
                                refCrack,
                                crack,
                                "Abnormal lane crack value detected!",
                                Duration(milliseconds: item.last),
                                false,
                              );
                              if (!warnings.contains(warning)) {
                                warnings.add(warning);
                              }
                            }

                            if (rut != null && refRut != null && rut > refRut) {
                              Warning warning = Warning(
                                ValType.rut,
                                refRut,
                                rut,
                                "Abnormal lane rut value detected!",
                                Duration(milliseconds: item.last),
                                false,
                              );
                              if (!warnings.contains(warning)) {
                                warnings.add(warning);
                              }
                            }

                            if (rough != null &&
                                refRough != null &&
                                rough > refRough) {
                              Warning warning = Warning(
                                ValType.roughness,
                                refRough,
                                rough,
                                "Abnormal lane roughness value detected!",
                                Duration(milliseconds: item.last),
                                false,
                              );
                              if (!warnings.contains(warning)) {
                                warnings.add(warning);
                              }
                            }

                            break;
                          } else {
                            final row = listData[listData.indexOf(item)];

                            final lat = double.tryParse(row[13].toString());
                            final lng = double.tryParse(row[14].toString());
                            final rough = double.tryParse(row[9].toString());
                            final rut = double.tryParse(row[10].toString());
                            final crack = double.tryParse(row[11].toString());
                            final area = double.tryParse(row[12].toString());

                            final refRough = double.tryParse(row[5].toString());
                            final refRut = double.tryParse(row[6].toString());
                            final refCrack = double.tryParse(row[7].toString());
                            final refArea = double.tryParse(row[8].toString());

                            if (lat != null && lng != null) {
                              trackPoints.add(LatLng(lat, lng));
                            }
                            if (rough != null) roughnessValues.add(rough);
                            if (rut != null) rutValues.add(rut);
                            if (crack != null) crackValues.add(crack);
                            if (area != null) areaValues.add(area);

                            if (area != null &&
                                refArea != null &&
                                area > refArea) {
                              Warning warning = Warning(
                                ValType.ravelling,
                                refArea,
                                area,
                                "Abnormal lane ravelling/area value detected!",
                                Duration(milliseconds: item.last),
                                false,
                              );
                              if (!warnings.contains(warning)) {
                                warnings.add(warning);
                              }
                            }

                            if (crack != null &&
                                refCrack != null &&
                                crack > refCrack) {
                              Warning warning = Warning(
                                ValType.crack,
                                refCrack,
                                crack,
                                "Abnormal lane crack value detected!",
                                Duration(milliseconds: item.last),
                                false,
                              );
                              if (!warnings.contains(warning)) {
                                warnings.add(warning);
                              }
                            }

                            if (rut != null && refRut != null && rut > refRut) {
                              Warning warning = Warning(
                                ValType.rut,
                                refRut,
                                rut,
                                "Abnormal lane rut value detected!",
                                Duration(milliseconds: item.last),
                                false,
                              );
                              if (!warnings.contains(warning)) {
                                warnings.add(warning);
                              }
                            }

                            if (rough != null &&
                                refRough != null &&
                                rough > refRough) {
                              Warning warning = Warning(
                                ValType.roughness,
                                refRough,
                                rough,
                                "Abnormal lane roughness value detected!",
                                Duration(milliseconds: item.last),
                                false,
                              );
                              if (!warnings.contains(warning)) {
                                warnings.add(warning);
                              }
                            }
                          }
                        }
                      }

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
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (BuildContext context) {
                                            return Dialog(
                                                backgroundColor:
                                                    Colors.transparent,
                                                insetPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 48),
                                                child: StatefulBuilder(builder:
                                                    (context,
                                                        setStateWarnings) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .redAccent,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              child: Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical: 6,
                                                                    horizontal:
                                                                        10),
                                                                child: Row(
                                                                  children: [
                                                                    Text(
                                                                      "Warnings",
                                                                      style: GoogleFonts.poppins(
                                                                          fontSize:
                                                                              18,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: () =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(),
                                                              child:
                                                                  const CircleAvatar(
                                                                radius: 16,
                                                                backgroundColor:
                                                                    Colors
                                                                        .black,
                                                                child: Icon(
                                                                    Icons.close,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 18),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        Flexible(
                                                          child:
                                                              warnings.isEmpty
                                                                  ? Container(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          0.2,
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      child:
                                                                          Text(
                                                                        "No Warnings found!",
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontSize:
                                                                              24,
                                                                        ),
                                                                      ),
                                                                    )
                                                                  : ListView
                                                                      .builder(
                                                                      shrinkWrap:
                                                                          true,
                                                                      padding:
                                                                          EdgeInsets
                                                                              .zero,
                                                                      itemCount:
                                                                          warnings
                                                                              .length,
                                                                      itemBuilder:
                                                                          (context,
                                                                              index) {
                                                                        if (warnings[index]
                                                                            .checkedOff) {
                                                                          return SizedBox();
                                                                        }
                                                                        return Container(
                                                                          margin: const EdgeInsets
                                                                              .symmetric(
                                                                              vertical: 6),
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              12),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                Colors.grey.shade100,
                                                                            borderRadius:
                                                                                BorderRadius.circular(12),
                                                                            border:
                                                                                Border.all(color: Colors.black12),
                                                                          ),
                                                                          child:
                                                                              Row(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.center,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.start,
                                                                            children: [
                                                                              GestureDetector(
                                                                                onTap: () {
                                                                                  warnings[index].checkedOff = true;
                                                                                  setStateWarnings(() {});
                                                                                  setstateInner(() {});
                                                                                },
                                                                                child: const Icon(Icons.check, color: Colors.black),
                                                                              ),
                                                                              const SizedBox(width: 12),
                                                                              Expanded(
                                                                                child: Column(
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Text(
                                                                                      '${warnings[index].valType.toString().toUpperCase().replaceAll("VALTYPE.", "")}: ${warnings[index].recvValue} / ${warnings[index].limit}',
                                                                                      style: TextStyle(
                                                                                        fontWeight: FontWeight.bold,
                                                                                        fontSize: 16,
                                                                                      ),
                                                                                    ),
                                                                                    SizedBox(height: 4),
                                                                                    Text(
                                                                                      "${warnings[index].message}\n⏰ ${formatDuration(warnings[index].duration)}",
                                                                                      style: TextStyle(
                                                                                        fontSize: 13,
                                                                                        color: Colors.black87,
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              GestureDetector(
                                                                                onTap: () {
                                                                                  videoPlayerController!.seekTo(warnings[index].duration);
                                                                                  Navigator.of(context).pop();
                                                                                },
                                                                                child: const Icon(Icons.arrow_forward_ios, size: 16),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }));
                                          },
                                        );
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
                                                        fontSize: 12,
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
                                                // Padding(
                                                //   padding:
                                                //       const EdgeInsets.only(
                                                //           bottom: 8, right: 8),
                                                //   child: GestureDetector(
                                                //     onTap: () {
                                                //       showVideoFullScreenDialog(
                                                //           position,
                                                //           duration,
                                                //           setstateInner);
                                                //     },
                                                //   ),
                                                // ),
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
                                        child: FlutterMap(
                                          mapController: MapController(),
                                          options: MapOptions(
                                            initialCenter: trackPoints.isEmpty
                                                ? LatLng(28.5428, 77.1555)
                                                : trackPoints.last,
                                            maxZoom: 20.0,
                                            minZoom: 2,
                                            interactionOptions:
                                                InteractionOptions(
                                              flags: InteractiveFlag.all,
                                            ),
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName:
                                                  'com.example.nhai_app',
                                            ),
                                            PolylineLayer(
                                              polylines: [
                                                if (trackPoints.isNotEmpty)
                                                  Polyline(
                                                    points: trackPoints,
                                                    color: Colors.black,
                                                    strokeWidth: 8,
                                                  ),
                                              ],
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                if (trackPoints.isNotEmpty)
                                                  Marker(
                                                    point: trackPoints.last,
                                                    width: 64,
                                                    height: 64,
                                                    rotate: true,
                                                    child: RotatedBox(
                                                      quarterTurns: 2,
                                                      child: Image.asset(
                                                          'assets/map_car.png'),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(2),
                                      1: FlexColumnWidth(2),
                                    },
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    children: [
                                      _buildTableHeader(
                                          'Type', 'Value', 'Limit'),
                                      _buildTableRow(
                                          'Chn',
                                          [],
                                          listData[index][1].toString(),
                                          'N.A.'),
                                      _buildTableRow(
                                          'Roughness',
                                          roughnessValues,
                                          listData[index][9].toString() +
                                              (listData[index][9] >
                                                      listData[index][5]
                                                  ? "  ❌"
                                                  : "  ✅"),
                                          listData[index][5].toString()),
                                      _buildTableRow(
                                          'Rut Depth',
                                          rutValues,
                                          listData[index][10].toString() +
                                              (listData[index][10] >
                                                      listData[index][6]
                                                  ? "  ❌"
                                                  : "  ✅"),
                                          listData[index][6].toString()),
                                      _buildTableRow(
                                          'Crack Area',
                                          crackValues,
                                          listData[index][11].toString() +
                                              (listData[index][11] >
                                                      listData[index][7]
                                                  ? "  ❌"
                                                  : "  ✅"),
                                          listData[index][7].toString()),
                                      _buildTableRow(
                                          'Lane Area',
                                          areaValues,
                                          listData[index][12].toString() +
                                              (listData[index][12] >
                                                      listData[index][8]
                                                  ? "  ❌"
                                                  : "  ✅"),
                                          listData[index][8].toString(),
                                          last: true),
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
                    });
              } else {
                return Text("Loading...");
              }
            }),
      ),
    );
  }
}
