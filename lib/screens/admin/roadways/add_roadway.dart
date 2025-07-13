import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nhai_app/api/admin_api.dart';
import 'package:nhai_app/api/exceptions.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/services/auth.dart';

class AddRoadwayScreen extends StatefulWidget {
  final AuthService authService;
  final User user;
  const AddRoadwayScreen({
    super.key,
    required this.authService,
    required this.user,
  });

  @override
  State<AddRoadwayScreen> createState() => _AddRoadwayScreenState();
}

class _AddRoadwayScreenState extends State<AddRoadwayScreen> {
  final TextEditingController _roadwayIdController = TextEditingController();
  final TextEditingController _roadwayNameController = TextEditingController();

  File? _roadwayImage;
  Uint8List? _webImageBytes;
  String? _webImageName;

  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _webImageName = picked.name;
          _roadwayImage = null;
        });
      } else {
        setState(() {
          _roadwayImage = File(picked.path);
          _webImageBytes = null;
          _webImageName = null;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_roadwayIdController.text.isEmpty ||
        _roadwayNameController.text.isEmpty ||
        (_roadwayImage == null && _webImageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("All fields and image are required",
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AdminApi().createRoadway(
        _roadwayIdController.text,
        _roadwayNameController.text,
        imageFile: _roadwayImage,
        webBytes: _webImageBytes,
        webFileName: _webImageName,
        onProgress: (sent, total) {},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Roadway created",
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

  @override
  Widget build(BuildContext context) {
    final redAccent = Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Roadway',
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
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    image: (_roadwayImage != null || _webImageBytes != null)
                        ? DecorationImage(
                            image: _roadwayImage != null
                                ? FileImage(_roadwayImage!)
                                : MemoryImage(_webImageBytes!) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: (_roadwayImage == null && _webImageBytes == null)
                      ? const Icon(Icons.add_photo_alternate,
                          color: Colors.black54, size: 48)
                      : null,
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
                label: 'Create Roadway',
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
