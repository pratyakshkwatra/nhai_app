import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhai_app/api/admin_api.dart';
import 'package:nhai_app/api/models/roadway.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/screens/admin/roadways/edit_roadway.dart';
import 'package:nhai_app/services/auth.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class RoadwaysHome extends StatefulWidget {
  final AuthService authService;
  final User user;
  const RoadwaysHome(
      {super.key, required this.authService, required this.user});

  @override
  State<RoadwaysHome> createState() => _RoadwaysHomeState();
}

class _RoadwaysHomeState extends State<RoadwaysHome> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<Roadway>> getRoadways() async {
    try {
      List<Roadway> roadways = await AdminApi().listRoadways();

      return roadways;
    } catch (_) {
      return [];
    }
  }

  Widget roadwayCard(Roadway roadway, int index) {
    final hasImage = roadway.imagePath != null && roadway.imagePath!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: MediaQuery.of(context).size.height * 0.16,
      width: double.infinity,
      decoration: BoxDecoration(
        color: hasImage ? Colors.black : Colors.red.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                color: Colors.black.withValues(alpha: 0.4),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.red.shade100,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
                loadingBuilder: (context, child, loadingProgress) =>
                    loadingProgress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.045,
                vertical: MediaQuery.of(context).size.height * 0.02,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                                  color: Colors.black),
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
                                  color: Colors.black),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return EditRoadwayScreen(
                              roadway: roadway,
                            );
                          },
                        ),
                      );
                    },
                    child: Icon(
                      Icons.edit,
                      size: 30,
                      color: Colors.white.withAlpha(220),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 30,
                    color: Colors.white.withAlpha(220),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                : ListView.builder(
                    itemCount: roadways.length,
                    itemBuilder: (context, index) {
                      final Roadway roadway = roadways[index];

                      return GestureDetector(
                        onTap: () {},
                        child: roadwayCard(roadway, index),
                      );
                    },
                  ),
          );
        });
  }
}
