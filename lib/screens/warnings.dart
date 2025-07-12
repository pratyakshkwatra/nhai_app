import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:nhai_app/models/warning.dart';
import 'package:nhai_app/screens/survey_vehicle_data_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class WarningsPage extends StatefulWidget {
  final List<Warning> warnings;
  final String videoPath;
  final String surveyName;
  const WarningsPage(
      {super.key,
      required this.warnings,
      required this.videoPath,
      required this.surveyName});

  @override
  State<WarningsPage> createState() => _WarningsPageState();
}

VideoPlayerController? videoPlayerController;

ChewieController? chewieController;

Chewie? playerWidget;

class _WarningsPageState extends State<WarningsPage> {
  Duration endDuration = Duration.zero;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoPath),
    );
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController!,
      autoPlay: false,
      looping: false,
      draggableProgressBar: true,
      showControls: true,
      aspectRatio: 0.52,
      allowMuting: true,
      allowPlaybackSpeedChanging: false,
      showOptions: true,
      allowFullScreen: true,
    );

    playerWidget = Chewie(
      controller: chewieController!,
    );

    videoPlayerController!.initialize().then((_) {
      setState(() {
        endDuration = videoPlayerController!.value.duration;
      });
    });
    _mapController = MapController();
  }

  @override
  void dispose() {
    videoPlayerController!.dispose();
    chewieController!.dispose();

    super.dispose();
  }

  LatLng getCenter(List<Warning> warnings) {
    if (warnings.isEmpty) return LatLng(28.5428, 77.1555);

    double totalLat = 0;
    double totalLng = 0;

    for (var warning in warnings) {
      totalLat += warning.cordinates.latitude;
      totalLng += warning.cordinates.longitude;
    }

    return LatLng(
      totalLat / warnings.length,
      totalLng / warnings.length,
    );
  }

  void showWarningPlayerDialog(BuildContext context, Widget playerWidget) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Warning Playback",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.close,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: playerWidget,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
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

  showCustomModalBottomSheet(Warning warning, TileProvider tileProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Warning",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Type: ${warning.valType.toString().split(".").last.toUpperCase()} - ${warning.recvValue}/${warning.limit}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      "Time: ${formatDuration(warning.duration)}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      warning.message,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w300,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: ElevatedButton(
                      onPressed: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          videoPlayerController!.seekTo(Duration(
                            milliseconds:
                                warning.duration.inMilliseconds - 5000,
                          ));
                          showWarningPlayerDialog(context, playerWidget!);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(
                            Icons.cut,
                            color: Colors.white,
                            size: 24,
                          ),
                          Text(
                            'Play Clip',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Processing Video Clip..."),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );

                        try {
                          final tempDir = await getTemporaryDirectory();
                          final filePath = '${tempDir.path}/temp_video.mp4';

                          File file;

                          if (widget.videoPath.startsWith('http')) {
                            final response =
                                await http.get(Uri.parse(widget.videoPath));
                            if (response.statusCode != 200) {
                              throw Exception('Failed to download video');
                            }
                            file = File(filePath);
                            await file.writeAsBytes(response.bodyBytes);
                          } else {
                            final byteData =
                                await rootBundle.load(widget.videoPath);
                            file = File(filePath);
                            await file
                                .writeAsBytes(byteData.buffer.asUint8List());
                          }

                          final videoTrimmer = VideoTrimmer();
                          await videoTrimmer.loadVideo(file.path);

                          final trimmedPath = await videoTrimmer.trimVideo(
                            startTimeMs: warning.duration.inMilliseconds - 5000,
                            endTimeMs: warning.duration.inMilliseconds + 5000,
                            includeAudio: true,
                          );

                          final hasVideo = trimmedPath != null &&
                              await File(trimmedPath).exists();

                          final message = '''
‼️ *WARNING* ‼️
*Survey*: ${widget.surveyName}

${warning.valType.toString().split(".").last.toUpperCase()} exceeded limit.
Received: ${warning.recvValue} | Limit: ${warning.limit}

Location: https://www.google.com/maps/search/?api=1&query=${warning.cordinates.latitude},${warning.cordinates.longitude}
${hasVideo ? "\n🎥 Attached: Video clip showing 5s before & after" : ""}
''';

                          await SharePlus.instance.share(
                            ShareParams(
                              text: message,
                              files: hasVideo ? [XFile(trimmedPath)] : [],
                            ),
                          );

                          await videoTrimmer.clearCache();
                        } catch (e) {
                          debugPrint("Share failed: $e");

                          final fallbackMessage = '''
‼️ *WARNING* ‼️
*Survey*: ${widget.surveyName}

${warning.valType.toString().split(".").last.toUpperCase()} exceeded limit.
Received: ${warning.recvValue} | Limit: ${warning.limit}

Location: https://www.google.com/maps/search/?api=1&query=${warning.cordinates.latitude},${warning.cordinates.longitude}
''';

                          await SharePlus.instance
                              .share(ShareParams(text: fallbackMessage));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(
                            Icons.share,
                            color: Colors.black,
                            size: 24,
                          ),
                          Text(
                            'Share',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 16,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.25,
                child: FutureBuilder(
                    future: getWorkingTileUrl(satelliteFallbackUrls),
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
                      return ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(
                          12,
                        ),
                        child: FlutterMap(
                          mapController: MapController(),
                          options: MapOptions(
                            initialCenter: warning.cordinates,
                            minZoom: 3,
                            maxZoom: 18,
                            initialZoom: 18,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: asyncSnapshot.data,
                              userAgentPackageName: 'com.example.nhai_app',
                              subdomains: ["a", "b", "c"],
                              tileProvider: tileProvider,
                            ),
                            MarkerLayer(markers: [
                              Marker(
                                point: warning.cordinates,
                                width: 160,
                                height: 64,
                                child: Image.asset(
                                  'assets/map_pin.png',
                                  height: 64,
                                  width: 64,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      );
                    }),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = getCenter(widget.warnings);
    final tileProvider = FMTCTileProvider(
      stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.05,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.arrow_back_ios,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Warnings",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              warnings.isEmpty
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.30,
                      child: Center(
                        child: Column(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
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
                  : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.85,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: FutureBuilder(
                                  future:
                                      getWorkingTileUrl(satelliteFallbackUrls),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Shimmer(
                                        color: Colors.white,
                                        colorOpacity: 0.75,
                                        child: Container(
                                          color: Colors.grey.shade300,
                                        ),
                                      );
                                    }
                                    return FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                        initialCenter: center,
                                        minZoom: 3,
                                        maxZoom: 18,
                                        initialZoom: 13,
                                        interactionOptions:
                                            const InteractionOptions(
                                          flags: InteractiveFlag.all,
                                        ),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate: snapshot.data,
                                          userAgentPackageName:
                                              'com.example.nhai_app',
                                          subdomains: ["a", "b", "c"],
                                          tileProvider: tileProvider,
                                        ),
                                        MarkerLayer(
                                          markers:
                                              widget.warnings.map((warning) {
                                            return Marker(
                                              point: warning.cordinates,
                                              width: 160,
                                              height: 64,
                                              child: GestureDetector(
                                                onTap: () {
                                                  showCustomModalBottomSheet(
                                                      warning, tileProvider);
                                                },
                                                child: Image.asset(
                                                  'assets/map_pin.png',
                                                  height: 64,
                                                  width: 64,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    );
                                  }),
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
