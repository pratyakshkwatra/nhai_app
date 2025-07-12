import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/screens/admin/officers/add_officer.dart';
import 'package:nhai_app/screens/admin/roadways/add_roadway.dart';
import 'package:nhai_app/screens/admin/roadways/roadways_home.dart';
import 'package:nhai_app/screens/admin/officers/users_home.dart';
import 'package:nhai_app/screens/auth/login.dart';
import 'package:nhai_app/services/auth.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';

class AdminHome extends StatefulWidget {
  final AuthService authService;
  final User user;

  const AdminHome({super.key, required this.authService, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int selectedIndex = 0;
  late final PageController pageController;

  @override
  void initState() {
    pageController = PageController();
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(48),
          topRight: Radius.circular(48),
        ),
        child: WaterDropNavBar(
          backgroundColor: Colors.redAccent,
          onItemSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
            pageController.animateToPage(
              selectedIndex,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutQuad,
            );
          },
          selectedIndex: selectedIndex,
          waterDropColor: Colors.black,
          inactiveIconColor: Colors.black,
          bottomPadding: kIsWeb ? 18: null,
          iconSize: 32,
          barItems: [
            BarItem(
              filledIcon: Icons.person,
              outlinedIcon: Icons.person_rounded,
            ),
            BarItem(
              filledIcon: Icons.directions_car,
              outlinedIcon: Icons.directions_car_rounded,
            ),
            BarItem(
              filledIcon: Icons.logout,
              outlinedIcon: Icons.logout_outlined,
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
        ),
        height: MediaQuery.of(context).size.height,
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
                        if (selectedIndex == 0) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return AddOfficerScreen(
                                  authService: widget.authService,
                                  user: widget.user,
                                );
                              },
                            ),
                          );
                          setState(() {});
                        } else if (selectedIndex == 1) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return AddRoadwayScreen(
                                  authService: widget.authService,
                                  user: widget.user,
                                );
                              },
                            ),
                          );
                        }
                        setState(() {});
                        pageController.animateToPage(
                          selectedIndex,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutQuad,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.redAccent,
                        ),
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.add,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView(
                    allowImplicitScrolling: false,
                    onPageChanged: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                      pageController.animateToPage(
                        selectedIndex,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutQuad,
                      );
                    },
                    controller: pageController,
                    children: [
                      UsersHome(
                        authService: widget.authService,
                        user: widget.user,
                      ),
                      RoadwaysHome(
                        authService: widget.authService,
                        user: widget.user,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Logout Confirmation",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "Are you sure you want to Log-Out?",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                SizedBox(
                                  height: 32,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.40,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await widget.authService
                                              .logout()
                                              .then((value) {
                                            if (context.mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return LoginScreen(
                                                      authService:
                                                          widget.authService,
                                                    );
                                                  },
                                                ),
                                              );
                                            }
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 4,
                                        ),
                                        child: Text(
                                          'Yes',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.40,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 4,
                                        ),
                                        child: Text(
                                          'No',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
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
      ),
    );
  }
}
