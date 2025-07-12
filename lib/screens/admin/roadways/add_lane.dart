import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nhai_app/api/admin_api.dart';
import 'package:nhai_app/api/exceptions.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/services/auth.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class AddLane extends StatefulWidget {
  final AuthService authService;
  final User user;
  final int roadwayId;

  const AddLane({
    super.key,
    required this.authService,
    required this.user,
    required this.roadwayId,
  });

  @override
  State<AddLane> createState() => _AddLaneState();
}

class _AddLaneState extends State<AddLane> {
  bool _isLoading = false;
  File? _videoFile;
  File? _excelFile;

  String _selectedDirection = 'L';
  String _selectedLaneNumber = '1';

  Future<void> _submit() async {
    final laneId = "$_selectedDirection$_selectedLaneNumber";

    if (_selectedLaneNumber.isEmpty ||
        _videoFile == null ||
        _excelFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("All fields are required",
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AdminApi().addLane(
        roadwayId: widget.roadwayId,
        laneId: laneId,
        direction: _selectedDirection,
        videoFile: _videoFile!,
        excelFile: _excelFile!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Lane created",
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context);
      }
    } on APIException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(e.message, style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile(bool isVideo) async {
    final result = await FilePicker.platform.pickFiles(
      type: isVideo ? FileType.video : FileType.custom,
      allowedExtensions: isVideo ? null : ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isVideo) {
          _videoFile = File(result.files.single.path!);
        } else {
          _excelFile = File(result.files.single.path!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final redAccent = Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Add Lane', style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDirection,
                            icon: const Icon(Icons.arrow_drop_down),
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(16),
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.black),
                            items: ['L', 'R']
                                .map((dir) => DropdownMenuItem(
                                      value: dir,
                                      child: Text("Direction $dir"),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedDirection = value);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLaneNumber,
                            icon: const Icon(Icons.arrow_drop_down),
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(16),
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.black),
                            items: List.generate(10, (i) => '${i + 1}')
                                .map((lane) => DropdownMenuItem(
                                      value: lane,
                                      child: Text("Lane $lane"),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedLaneNumber = value);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FilePickerCard(
                label: 'Pick Video File',
                file: _videoFile,
                icon: Icons.videocam_rounded,
                fileType: 'video',
                onTap: () => _pickFile(true),
              ),
              const SizedBox(height: 12),
              _FilePickerCard(
                label: 'Pick Excel Sheet',
                file: _excelFile,
                icon: Icons.grid_on_rounded,
                fileType: 'excel',
                onTap: () => _pickFile(false),
              ),
              const SizedBox(height: 24),
              _RoundedButton(
                label: 'Create Lane',
                color: redAccent,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundedButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _RoundedButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null ? color.withAlpha(150) : color,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : Text(label,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _FilePickerCard extends StatelessWidget {
  final String label;
  final File? file;
  final IconData icon;
  final String fileType;
  final VoidCallback onTap;

  const _FilePickerCard({
    required this.label,
    required this.file,
    required this.icon,
    required this.fileType,
    required this.onTap,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "\${(bytes / 1024).toStringAsFixed(1)} KB";
    return "\${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  @override
  Widget build(BuildContext context) {
    final fileName = file?.path.split('/').last;
    final fileSize = file != null ? _formatBytes(file!.lengthSync()) : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.black54),
            const SizedBox(width: 16),
            Expanded(
              child: file != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fileName ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            )),
                        Text(fileSize ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black54,
                            )),
                      ],
                    )
                  : Text(label,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey,
                      )),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.upload_rounded, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
