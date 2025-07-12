import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nhai_app/api/models/lane.dart';
import 'package:nhai_app/api/models/roadway.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/api/officer_api.dart';
import 'package:nhai_app/screens/survey_vehicle_data_screen.dart';
import 'package:nhai_app/services/auth.dart';
import 'package:recase/recase.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class RoadwaysOfficer extends StatefulWidget {
  final AuthService authService;
  final User user;
  final Function onView;

  const RoadwaysOfficer(
      {super.key,
      required this.authService,
      required this.user,
      required this.onView});

  @override
  State<RoadwaysOfficer> createState() => _RoadwaysOfficerState();
}

class _RoadwaysOfficerState extends State<RoadwaysOfficer> {
  Set<int> expandedTiles = {};
  int? viewedIndex;

  @override
  void initState() {
    super.initState();
  }

  Future<List<Roadway>> getRoadways() async {
    try {
      List<Roadway> roadways = await OfficerApi().getMyRoadways();

      return roadways;
    } catch (_) {
      return [];
    }
  }

  Future<List<Lane>> getLanes(int roadwayID) async {
    try {
      List<Lane> lanes = await OfficerApi().getLanes(roadwayID);

      return lanes;
    } catch (_) {
      return [];
    }
  }

  Widget roadwayCard(Roadway roadway, int index) {
    final hasImage = roadway.imagePath != null && roadway.imagePath!.isNotEmpty;
    bool isExpanded = expandedTiles.contains(index);

    return StatefulBuilder(
      builder: (context, setStateInternal) {
        return Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            onExpansionChanged: (expanded) {
              setState(() {
                if (expanded) {
                  expandedTiles.add(index);
                } else {
                  expandedTiles.remove(index);
                }
              });
              setStateInternal(() {});
            },
            showTrailingIcon: false,
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: MediaQuery.of(context).size.height * 0.16,
              width: double.infinity,
              decoration: BoxDecoration(
                
                color: hasImage ? Colors.black : Colors.red.shade100,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
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
                      Image.network(
                        roadway.imagePath!,
                        fit: BoxFit.cover,
                        color: Colors.black.withAlpha(100),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.red.shade100,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, size: 48),
                        ),
                        loadingBuilder: (_, child, loadingProgress) =>
                            loadingProgress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator()),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.045,
                        vertical: MediaQuery.of(context).size.height * 0.02,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  roadway.roadwayId,
                                  maxLines: 1,
                                  minFontSize: 10,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    shadows: const [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 3,
                                        color: Colors.black,
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AutoSizeText(
                                  roadway.name,
                                  maxLines: 2,
                                  minFontSize: 12,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    shadows: const [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 4,
                                        color: Colors.black,
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                        opacity: animation, child: child),
                                child: GestureDetector(
                                  key: ValueKey(viewedIndex == index),
                                  onTap: () {
                                    setState(() {
                                      if (viewedIndex == index) {
                                        viewedIndex = null;
                                        widget.onView(null);
                                      } else {
                                        viewedIndex = index;
                                        widget.onView(index);
                                      }
                                    });
                                  },
                                  child: Icon(
                                    viewedIndex == index
                                        ? Icons.close_rounded
                                        : Icons.visibility,
                                    size: 32,
                                    color: Colors.white.withAlpha(220),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              AnimatedRotation(
                                turns: isExpanded ? 0.25 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 32,
                                  color: Colors.white.withAlpha(220),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: isExpanded
                    ? Container(
                        key: const ValueKey(true),
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Lanes",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: StreamBuilder(
                                  stream: Stream.periodic(
                                    const Duration(milliseconds: 1500),
                                  ),
                                  builder: (context, asyncSnapshotStream) {
                                    return FutureBuilder(
                                        future: getLanes(roadway.id),
                                        builder: (context, asyncSnapshot) {
                                          if (!asyncSnapshot.hasData) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadiusGeometry.circular(
                                                      24),
                                              child: Shimmer(
                                                color: Colors.red.shade200,
                                                colorOpacity: 0.75,
                                                child: Container(
                                                  color: Colors.red.shade100,
                                                ),
                                              ),
                                            );
                                          }

                                          List<Lane> lanes =
                                              asyncSnapshot.data!;
                                          return Container(
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: lanes.isEmpty
                                                ? Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        "No Data Available",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 24,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 18),
                                                        child: Text(
                                                          "Click the add (+) icon in the top right corner to add a new lane",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontWeight:
                                                                FontWeight.w300,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : ListView.builder(
                                                    itemCount: lanes.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      Lane lane = lanes[index];

                                                      return lane.data == null
                                                          ? ClipRRect(
                                                              borderRadius:
                                                                  BorderRadiusGeometry
                                                                      .circular(
                                                                          18),
                                                              child: Shimmer(
                                                                color: Colors
                                                                    .red
                                                                    .shade100,
                                                                colorOpacity:
                                                                    0.75,
                                                                child:
                                                                    Container(
                                                                  height: 64,
                                                                  color: Colors
                                                                      .red
                                                                      .shade200,
                                                                ),
                                                              ),
                                                            )
                                                          : Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          6),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .red
                                                                    .shade100
                                                                    .withValues(
                                                                        alpha:
                                                                            0.6),
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .redAccent
                                                                      .withValues(
                                                                          alpha:
                                                                              0.1),
                                                                  width: 3,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              child: ListTile(
                                                                dense: true,
                                                                title: Row(
                                                                  children: [
                                                                    Text(
                                                                      "${lane.laneId} ",
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontSize:
                                                                            20,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      lane.data!.processingPercent !=
                                                                              100
                                                                          ? "(${ReCase(lane.data!.processingStatus).titleCase})"
                                                                          : "",
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.w300,
                                                                        fontSize:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                subtitle: lane
                                                                            .data!
                                                                            .processingPercent ==
                                                                        100
                                                                    ? Text(
                                                                        "Created at: ${DateFormat('dd-MM-yyyy HH:mm').format(lane.data!.createdAt)}",
                                                                        style: GoogleFonts.poppins(
                                                                            fontWeight: FontWeight
                                                                                .w300,
                                                                            fontSize:
                                                                                12,
                                                                            color:
                                                                                Colors.black),
                                                                      )
                                                                    : ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadiusGeometry.circular(12),
                                                                        child:
                                                                            Stack(
                                                                          alignment:
                                                                              Alignment.center,
                                                                          children: [
                                                                            LinearProgressIndicator(
                                                                              value: lane.data!.processingPercent / 100,
                                                                              minHeight: 18,
                                                                              color: Colors.redAccent,
                                                                              backgroundColor: Colors.black,
                                                                            ),
                                                                            Text(
                                                                              ReCase(lane.data!.statusMsg).titleCase,
                                                                              style: GoogleFonts.poppins(
                                                                                fontWeight: FontWeight.w500,
                                                                                fontSize: 12,
                                                                                color: Colors.white,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                trailing:
                                                                    GestureDetector(
                                                                  onTap: () {
                                                                    if (lane.data !=
                                                                        null) {
                                                                      if (lane
                                                                              .data!
                                                                              .videoPath!
                                                                              .isNotEmpty &&
                                                                          lane
                                                                              .data!
                                                                              .xlsxPath!
                                                                              .isNotEmpty) {
                                                                        Navigator
                                                                            .push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder:
                                                                                (context) {
                                                                              return SurveyVehicleDataScreen(
                                                                                videoPath: lane.data!.videoPath!,
                                                                                csvPath: lane.data!.xlsxPath!,
                                                                                lane: lane.laneId,
                                                                                roadWay: roadway.name,
                                                                              );
                                                                            },
                                                                          ),
                                                                        );
                                                                      }
                                                                    }
                                                                  },
                                                                  child:
                                                                      const Icon(
                                                                    Icons
                                                                        .arrow_forward_ios_rounded,
                                                                    color: Colors
                                                                        .black54,
                                                                    size: 20,
                                                                  ),
                                                                ),
                                                                contentPadding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            3,
                                                                        horizontal:
                                                                            16),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                ),
                                                              ),
                                                            );
                                                    },
                                                  ),
                                          );
                                        });
                                  }),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey(false)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getRoadways(),
        builder: (context, asyncSnapshot) {
          if (!asyncSnapshot.hasData) {
            return ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(24),
              child: Shimmer(
                color: Colors.white,
                colorOpacity: 0.75,
                child: Container(
                  color: Colors.grey.shade300,
                ),
              ),
            );
          }

          List<Roadway> roadways = asyncSnapshot.data!;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: roadways.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "No Data Available",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          "Click the add (+) icon in the top right corner to add a new inspection officer account",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w300,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ListView.builder(
                      itemCount: roadways.length,
                      itemBuilder: (context, index) {
                        final Roadway roadway = roadways[index];

                        return GestureDetector(
                          onTap: () {},
                          child: roadwayCard(roadway, index),
                        );
                      },
                    ),
                  ),
          );
        });
  }
}
