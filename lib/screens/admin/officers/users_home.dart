import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhai_app/api/admin_api.dart';
import 'package:nhai_app/api/exceptions.dart';
import 'package:nhai_app/api/models/inspection_officer.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/screens/admin/home.dart';
import 'package:nhai_app/screens/admin/officers/edit_officer.dart';
import 'package:nhai_app/services/auth.dart';
import 'package:recase/recase.dart';
import 'package:intl/intl.dart';

class UsersHome extends StatefulWidget {
  final AuthService authService;
  final User user;
  const UsersHome({super.key, required this.authService, required this.user});

  @override
  State<UsersHome> createState() => _UsersHomeState();
}

class _UsersHomeState extends State<UsersHome> {
  final TextEditingController _searchController = TextEditingController();
  List<InspectionOfficer> allOfficers = [];
  List<InspectionOfficer> filteredOfficers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterOfficers);
  }

  Future<void> _fetchUsers() async {
    try {
      allOfficers = await AdminApi().listOfficers();
      filteredOfficers = List.from(allOfficers);
    } catch (_) {
      allOfficers = [];
      filteredOfficers = [];
    }
    setState(() => _isLoading = false);
  }

  void _filterOfficers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredOfficers = allOfficers.where((officer) {
        return officer.username.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(color: Colors.black),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                hintText: "Search officers...",
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
          if (!_isLoading && filteredOfficers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text("No matching officers found",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, color: Colors.grey)),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent))
                : ListView.builder(
                    itemCount: filteredOfficers.length,
                    itemBuilder: (context, index) {
                      final inspectionOfficer = filteredOfficers[index];
                      final imageUrl = inspectionOfficer.profilePicture;
                      final username = inspectionOfficer.username;

                      return Container(
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
                                    "Created at: ${DateFormat('dd-MM-yyyy HH:mm').format(
                                      inspectionOfficer.createdAt,
                                    )}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.black),
                              color: Colors.white,
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditOfficerScreen(
                                        authService: widget.authService,
                                        user: widget.user,
                                        inspectionOfficer: inspectionOfficer,
                                      ),
                                    ),
                                  );
                                  if (mounted) setState(() {});
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text("Deletion Confirmation",
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black)),
                                      content: Text(
                                        "Are you sure you want to delete this officer account?",
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black87),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text("No",
                                              style: GoogleFonts.poppins(
                                                  color: Colors.black)),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text("Yes",
                                              style: GoogleFonts.poppins(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await AdminApi()
                                          .deleteOfficer(inspectionOfficer.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Profile deleted',
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
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AdminHome(
                                              authService: widget.authService,
                                              user: widget.user,
                                            ),
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

                                    if (mounted) setState(() {});
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit,
                                          color: Colors.black, size: 20),
                                      const SizedBox(width: 8),
                                      Text("Edit Profile",
                                          style: GoogleFonts.poppins(
                                              color: Colors.black)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          color: Colors.redAccent, size: 20),
                                      const SizedBox(width: 8),
                                      Text("Delete Profile",
                                          style: GoogleFonts.poppins(
                                              color: Colors.redAccent)),
                                    ],
                                  ),
                                ),
                              ],
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
  }
}
