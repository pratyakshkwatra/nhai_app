import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhai_app/api/admin_api.dart';
import 'package:nhai_app/api/models/inspection_officer.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/screens/admin/officers/edit_officer.dart';
import 'package:nhai_app/services/auth.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:recase/recase.dart';

class UsersHome extends StatefulWidget {
  final AuthService authService;
  final User user;
  const UsersHome({super.key, required this.authService, required this.user});

  @override
  State<UsersHome> createState() => _UsersHomeState();
}

class _UsersHomeState extends State<UsersHome> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<InspectionOfficer>> getUsers() async {
    try {
      List<InspectionOfficer> officers = await AdminApi().listOfficers();
      return officers;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getUsers(),
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

          List<InspectionOfficer> officers = asyncSnapshot.data!;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: officers.isEmpty
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
                    itemCount: officers.length,
                    itemBuilder: (context, index) {
                      final inspectionOfficer = officers[index];
                      final imageUrl = inspectionOfficer.profilePicture;
                      final username = inspectionOfficer.username;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditOfficerScreen(
                                authService: widget.authService,
                                user: widget.user,
                                inspectionOfficer: inspectionOfficer,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: imageUrl.isNotEmpty
                                      ? Colors.transparent
                                      : Colors.redAccent.shade100.withAlpha(50),
                                  image: imageUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: imageUrl.isEmpty
                                    ? const Icon(Icons.person,
                                        size: 28, color: Colors.black)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ReCase(username.split("_").join(" "))
                                          .titleCase,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Tap to edit officer profile",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 24,
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        });
  }
}
