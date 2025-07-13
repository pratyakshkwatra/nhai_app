import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nhai_app/api/admin_api.dart';
import 'package:nhai_app/api/exceptions.dart';
import 'package:nhai_app/api/models/lane.dart';
import 'package:nhai_app/api/models/roadway.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/screens/admin/roadways/add_lane.dart';
import 'package:nhai_app/screens/admin/roadways/assign_officers.dart';
import 'package:nhai_app/screens/admin/roadways/edit_roadway.dart';
import 'package:nhai_app/screens/survey_vehicle_data_screen.dart';
import 'package:nhai_app/services/auth.dart';
import 'package:recase/recase.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class RoadwaysHome extends StatefulWidget {
  final AuthService authService;
  final User user;
  const RoadwaysHome(
      {super.key, required this.authService, required this.user});

  @override
  State<RoadwaysHome> createState() => _RoadwaysHomeState();
}

List<Roadway> _allRoadways = [];
List<Roadway> _filteredRoadways = [];

class _RoadwaysHomeState extends State<RoadwaysHome> {
  Set<int> expandedTiles = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoadways();
  }

  void _filterRoadways(String query) {
    setState(() {
      _filteredRoadways = _allRoadways.where((r) {
        final nameMatch = r.name.toLowerCase().contains(query.toLowerCase());
        final idMatch = r.roadwayId.toString().contains(query);
        return nameMatch || idMatch;
      }).toList();
    });
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
              margin:  EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.00675),
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
                                 SizedBox(height: MediaQuery.of(context).size.height * 0.00675),
                                AutoSizeText(
                                  roadway.name,
                                  maxLines: 2,
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
                           SizedBox(width: MediaQuery.of(context).size.width * 0.0125),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: Colors.white.withAlpha(220),
                              size: 30,
                            ),
                            color: Colors.white,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditRoadwayScreen(roadway: roadway),
                                  ),
                                );

                                if (mounted && updated == true) {
                                  await Future.delayed(
                                      const Duration(milliseconds: 2000));
                                  setState(() {});
                                }
                              } else if (value == 'manage_access') {
                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AssignOfficersScreen(roadway: roadway),
                                  ),
                                );

                                if (mounted && updated == true) {
                                  await Future.delayed(
                                      const Duration(milliseconds: 2000));
                                  setState(() {});
                                }
                              } else if (value == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    backgroundColor: Colors.white,
                                    title: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.black),
                                        SizedBox(width: 8),
                                        Text(
                                          'Confirm Deletion',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete this roadway?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          'No',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(
                                          'Yes',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  try {
                                    await AdminApi().deleteRoadway(
                                      roadway.id,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Roadway deleted',
                                            style: GoogleFonts.poppins(
                                                color: Colors.white),
                                          ),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  } on APIException catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(e.message,
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white)),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  }

                                  if (mounted) {
                                    setState(() {});
                                  }
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 22,
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      'Edit Roadway',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'manage_access',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      size: 22,
                                      color: Colors.black,
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      'Manage Access',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 22,
                                      color: Colors.redAccent,
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      'Delete Roadway',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: isExpanded ? 0.25 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 30,
                              color: Colors.white.withAlpha(220),
                            ),
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
                        margin:  EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.0125),
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
                        padding:  EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.025, vertical: MediaQuery.of(context).size.width * 0.0125),
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
                                GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return AddLane(
                                              authService: widget.authService,
                                              user: widget.user,
                                              roadwayId: roadway.id,
                                            );
                                          },
                                        ),
                                      );
                                      setState(() {});
                                    },
                                    child: const Icon(Icons.add,
                                        color: Colors.black54)),
                              ],
                            ),
                             SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
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
                                                                            AutoSizeText(
                                                                              ReCase(lane.data!.statusMsg).titleCase,
                                                                              maxLines: 1,
                                                                              style: GoogleFonts.poppins(
                                                                                fontWeight: FontWeight.w500,
                                                                                fontSize: 12,
                                                                                color: Colors.white,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                trailing: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    IconButton(
                                                                      icon:
                                                                          const Icon(
                                                                        Icons
                                                                            .delete,
                                                                        color: Colors
                                                                            .black,
                                                                        size:
                                                                            22,
                                                                      ),
                                                                      onPressed:
                                                                          () async {
                                                                        final confirmed =
                                                                            await showDialog<bool>(
                                                                          context:
                                                                              context,
                                                                          barrierDismissible:
                                                                              true,
                                                                          builder: (context) =>
                                                                              AlertDialog(
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(20),
                                                                            ),
                                                                            backgroundColor:
                                                                                Colors.white,
                                                                            title:
                                                                                Row(
                                                                              children: [
                                                                                Icon(Icons.delete, color: Colors.black),
                                                                                SizedBox(width: 8),
                                                                                Text(
                                                                                  'Confirm Deletion',
                                                                                  style: GoogleFonts.poppins(
                                                                                    fontWeight: FontWeight.bold,
                                                                                    color: Colors.black,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            content:
                                                                                Text(
                                                                              'Are you sure you want to delete this lane?',
                                                                              style: GoogleFonts.poppins(
                                                                                fontSize: 16,
                                                                                color: Colors.black87,
                                                                              ),
                                                                            ),
                                                                            actions: [
                                                                              TextButton(
                                                                                onPressed: () => Navigator.pop(context, false),
                                                                                child: Text(
                                                                                  'No',
                                                                                  style: GoogleFonts.poppins(
                                                                                    fontWeight: FontWeight.w500,
                                                                                    color: Colors.black,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              ElevatedButton(
                                                                                style: ElevatedButton.styleFrom(
                                                                                  backgroundColor: Colors.redAccent,
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(10),
                                                                                  ),
                                                                                ),
                                                                                onPressed: () => Navigator.pop(context, true),
                                                                                child: Text(
                                                                                  'Yes',
                                                                                  style: GoogleFonts.poppins(
                                                                                    color: Colors.white,
                                                                                    fontWeight: FontWeight.w600,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );

                                                                        if (confirmed ==
                                                                            true) {
                                                                          try {
                                                                            await AdminApi().deleteLane(lane.id);
                                                                            if (context.mounted) {
                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                SnackBar(
                                                                                  content: Text("Lane deleted", style: GoogleFonts.poppins(color: Colors.white)),
                                                                                  backgroundColor: Colors.redAccent,
                                                                                  behavior: SnackBarBehavior.floating,
                                                                                  margin: const EdgeInsets.all(16),
                                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                                ),
                                                                              );
                                                                            }

                                                                            setState(() {});
                                                                          } on APIException catch (e) {
                                                                            if (context.mounted) {
                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                SnackBar(
                                                                                  content: Text(e.message, style: GoogleFonts.poppins(color: Colors.white)),
                                                                                  backgroundColor: Colors.redAccent,
                                                                                  behavior: SnackBarBehavior.floating,
                                                                                  margin: const EdgeInsets.all(16),
                                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                                ),
                                                                              );
                                                                            }
                                                                          }
                                                                        }
                                                                      },
                                                                    ),
                                                                    GestureDetector(
                                                                      onTap:
                                                                          () {
                                                                        if (lane.data !=
                                                                            null) {
                                                                          if (lane.data!.videoPath!.isNotEmpty &&
                                                                              lane.data!.xlsxPath!.isNotEmpty) {
                                                                            Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                builder: (context) {
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
                                                                        size:
                                                                            20,
                                                                      ),
                                                                    ),
                                                                  ],
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

  Future<void> _loadRoadways() async {
    try {
      List<Roadway> roadways = await AdminApi().listRoadways();
      setState(() {
        _allRoadways = roadways;
        _filteredRoadways = roadways;
      });
    } catch (_) {
      setState(() {
        _allRoadways = [];
        _filteredRoadways = [];
      });
    }
  }

  Future<List<Lane>> getLanes(int roadwayID) async {
    try {
      return await AdminApi().getLanes(roadwayID);
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterRoadways,
              style: GoogleFonts.poppins(color: Colors.black),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: _loadRoadways,
                ),
                hintText: "Search roadways...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredRoadways.isEmpty
                ? Center(
                    child: Text(
                      "No Data Available",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),
                  )
                : ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(12),
                  child: ListView.builder(
                      itemCount: _filteredRoadways.length,
                      itemBuilder: (context, index) {
                        final Roadway roadway = _filteredRoadways[index];
                        return GestureDetector(
                          onTap: () {},
                          child: roadwayCard(roadway, index),
                        );
                      },
                    ),
                ),
          ),
        ],
      ),
    );
  }
}
