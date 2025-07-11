import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nhai_app/api/auth_api.dart';
import 'package:nhai_app/api/models/user.dart';
import 'package:nhai_app/main.dart';
import 'package:nhai_app/screens/admin/home.dart';
import 'package:nhai_app/screens/auth/login.dart';
import 'package:nhai_app/screens/inspection_officer/home.dart';
import 'package:nhai_app/services/auth.dart';

class LoadingScreen extends StatefulWidget {
  final AuthAPI authAPI;
  final FlutterSecureStorage secureStorage;
  const LoadingScreen({
    super.key,
    required this.authAPI,
    required this.secureStorage,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

AuthService _authService = AuthService(authAPI, secureStorage);

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    checkAndLoad();
    super.initState();
  }

  Future<void> checkAndLoad() async {
    User? user = await _authService.initializeSession();
    if (user != null) {
      if (mounted) {
        if (user.role == Roles.admin) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return AdminHome(
                  authService: _authService,
                  user: user,
                );
              },
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return InspectionHome(
                  authService: _authService,
                  user: user,
                );
              },
            ),
          );
        }
      }
    } else {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return LoginScreen(
                authService: _authService,
              );
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 8,
              color: Colors.redAccent,
              year2023: false,
            )
          ],
        ),
      ),
    );
  }
}
