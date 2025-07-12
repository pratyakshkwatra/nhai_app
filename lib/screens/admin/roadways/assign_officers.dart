import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nhai_app/api/admin_api.dart';
import 'package:nhai_app/api/models/inspection_officer.dart';
import 'package:nhai_app/api/models/roadway.dart';
import 'package:nhai_app/api/exceptions.dart';
import 'package:recase/recase.dart';

class AssignOfficersScreen extends StatefulWidget {
  final Roadway roadway;
  const AssignOfficersScreen({super.key, required this.roadway});

  @override
  State<AssignOfficersScreen> createState() => _AssignOfficersScreenState();
}

class _AssignOfficersScreenState extends State<AssignOfficersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<InspectionOfficer> allOfficers = [];
  List<InspectionOfficer> filteredOfficers = [];
  Set<int> initiallySelectedOfficerIds = {};
  Set<int> selectedOfficerIds = {};
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchOfficers();
    _searchController.addListener(_filter);
  }

  Future<void> _fetchOfficers() async {
    try {
      final all = await AdminApi().listOfficers();
      final assigned =
          await AdminApi().getOfficersWithAccess(widget.roadway.id);
      allOfficers = all;
      initiallySelectedOfficerIds = assigned.map((e) => e.id).toSet();
      selectedOfficerIds = Set.from(initiallySelectedOfficerIds);
      filteredOfficers = List.from(allOfficers);
    } catch (_) {
      allOfficers = [];
      filteredOfficers = [];
    }
    setState(() => isLoading = false);
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredOfficers = allOfficers
          .where((o) => o.username.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _submit() async {
    setState(() => isSubmitting = true);
    try {
      final accessMap = {
        for (final officer in allOfficers)
          officer.id: selectedOfficerIds.contains(officer.id)
      };
      await AdminApi().updateAccess(accessMap, widget.roadway.id);
      if (mounted) Navigator.pop(context, true);
    } on APIException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message,
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Widget _buildOfficerTile(InspectionOfficer officer) {
    final isSelected = selectedOfficerIds.contains(officer.id);
    final imageUrl = officer.profilePicture;
    final username = ReCase(officer.username.split("_").join(" ")).titleCase;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.shade100 : Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
                ? const Icon(Icons.person, size: 28, color: Colors.black)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                AutoSizeText(
                  "Created at: ${DateFormat('dd-MM-yyyy HH:mm').format(officer.createdAt)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: isSelected,
            onChanged: (_) {
              setState(() {
                if (isSelected) {
                  selectedOfficerIds.remove(officer.id);
                } else {
                  selectedOfficerIds.add(officer.id);
                }
              });
            },
            activeColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Officers to ${widget.roadway.roadwayId}',
            style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search officers...",
                  hintStyle: GoogleFonts.poppins(),
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
              ),
            ),
            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.redAccent),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredOfficers.length,
                  itemBuilder: (context, index) =>
                      _buildOfficerTile(filteredOfficers[index]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Assign Selected Officers',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
