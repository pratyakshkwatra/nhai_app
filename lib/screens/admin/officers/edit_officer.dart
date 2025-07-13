import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nhai_app/api/admin_api.dart';
import 'package:nhai_app/api/exceptions.dart';
import 'package:nhai_app/api/models/inspection_officer.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/services/auth.dart';

class EditOfficerScreen extends StatefulWidget {
  final AuthService authService;
  final InspectionOfficer inspectionOfficer;
  final User user;

  const EditOfficerScreen({
    super.key,
    required this.authService,
    required this.inspectionOfficer,
    required this.user,
  });

  @override
  State<EditOfficerScreen> createState() => _EditOfficerScreenState();
}

class _EditOfficerScreenState extends State<EditOfficerScreen> {
  late TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();
  File? _newProfileImage;
  Uint8List? _webImageBytes;
  String? _webImageName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.inspectionOfficer.username);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _webImageName = image.name;
        });
      } else {
        setState(() {
          _newProfileImage = File(image.path);
        });
      }
    }
  }

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    final pass =
        List.generate(10, (_) => chars[rand.nextInt(chars.length)]).join();
    _passwordController.text = pass;
    Clipboard.setData(ClipboardData(text: pass));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password generated & copied!',
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _submit() async {
    setState(() => _isLoading = true);
    try {
      await AdminApi().updateOfficer(
        widget.inspectionOfficer.id,
        _usernameController.text.isNotEmpty ? _usernameController.text : null,
        _passwordController.text.isNotEmpty ? _passwordController.text : null,
        kIsWeb ? _webImageBytes : _newProfileImage,
        fileName: _webImageName,
        onProgress: (sent, total) {
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } on APIException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message,
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final redAccent = Colors.redAccent;
    final currentProfilePic = widget.inspectionOfficer.profilePicture;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Officer Profile',
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
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _webImageBytes != null
                          ? MemoryImage(_webImageBytes!)
                          : _newProfileImage != null
                              ? FileImage(_newProfileImage!)
                              : (currentProfilePic != ""
                                  ? NetworkImage(currentProfilePic)
                                  : null) as ImageProvider?,
                      child: (_newProfileImage == null &&
                              _webImageBytes == null &&
                              currentProfilePic == "")
                          ? const Icon(Icons.person,
                              size: 48, color: Colors.black)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Only changed fields will be updated',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _RoundedInputField(
                controller: _usernameController,
                hintText: 'Username',
                icon: Icons.person,
                isPassword: false,
              ),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  _RoundedInputField(
                    controller: _passwordController,
                    hintText: 'New Password (optional)',
                    icon: Icons.lock,
                    isPassword: true,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: Colors.black),
                        onPressed: _generatePassword,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.black),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _passwordController.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Password copied!',
                                  style:
                                      GoogleFonts.poppins(color: Colors.white)),
                              backgroundColor: Colors.black,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),
              _RoundedButton(
                label: 'Update Profile',
                color: redAccent,
                isLoading: _isLoading,
                onPressed: () {
                  if (!_isLoading) {
                    _submit();
                  }
                },
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
      color: onPressed == null ? color.withValues(alpha: 153) : color,
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
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
