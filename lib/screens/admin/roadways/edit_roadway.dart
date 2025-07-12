import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nhai_app/api/admin_api.dart';
import 'package:nhai_app/api/exceptions.dart';
import 'package:nhai_app/api/models/roadway.dart';

class EditRoadwayScreen extends StatefulWidget {
  final Roadway roadway;
  const EditRoadwayScreen({super.key, required this.roadway});

  @override
  State<EditRoadwayScreen> createState() => _EditRoadwayScreenState();
}

class _EditRoadwayScreenState extends State<EditRoadwayScreen> {
  final TextEditingController _roadwayIdController = TextEditingController();
  final TextEditingController _roadwayNameController = TextEditingController();
  Uint8List? _roadwayImageBytes;
  String? _imageFilename;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _roadwayIdController.text = widget.roadway.roadwayId;
    _roadwayNameController.text = widget.roadway.name;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _roadwayImageBytes = bytes;
        _imageFilename = picked.name;
      });
    }
  }

  Future<void> _submit() async {
    if (_roadwayIdController.text.isEmpty ||
        _roadwayNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Roadway ID and Name are required",
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await AdminApi().updateRoadway(
        widget.roadway.id,
        _roadwayNameController.text,
        _roadwayIdController.text,
        imageBytes: _roadwayImageBytes,
        filename: _imageFilename,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Roadway updated",
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));

        Navigator.pop(context, true);
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
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final redAccent = Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Roadway',
            style: GoogleFonts.poppins(color: Colors.black)),
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
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        image: _roadwayImageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_roadwayImageBytes!),
                                fit: BoxFit.cover,
                              )
                            : (widget.roadway.imagePath != null &&
                                    widget.roadway.imagePath!.isNotEmpty)
                                ? DecorationImage(
                                    image:
                                        NetworkImage(widget.roadway.imagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      alignment: Alignment.center,
                      child: _roadwayImageBytes == null &&
                              (widget.roadway.imagePath == null ||
                                  widget.roadway.imagePath!.isEmpty)
                          ? Icon(Icons.add_photo_alternate,
                              color: Colors.black54, size: 48)
                          : null,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _RoundedInputField(
                controller: _roadwayIdController,
                hintText: 'Roadway ID (e.g. NH2)',
                icon: Icons.abc,
                isPassword: false,
              ),
              const SizedBox(height: 16),
              _RoundedInputField(
                controller: _roadwayNameController,
                hintText: 'Roadway Name (e.g. Delhi - Mumbai Expressway)',
                icon: Icons.directions_car,
                isPassword: false,
              ),
              const SizedBox(height: 24),
              _RoundedButton(
                label: 'Save Changes',
                color: redAccent,
                isLoading: _isUpdating,
                onPressed: _isUpdating ? null : _submit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundedInputField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;

  const _RoundedInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.isPassword,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.poppins(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black),
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
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
      color: onPressed == null ? color.withValues(alpha: 0.6) : color,
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
