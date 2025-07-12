import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nhai_app/api/auth_api.dart';
import 'package:nhai_app/screens/loading.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await FMTCObjectBoxBackend().initialise(
      maxDatabaseSize: 100000000,
    );
    await FMTCStore('mapStore').manage.create();
  }
  runApp(const MyApp());
}

AuthAPI authAPI = AuthAPI();
FlutterSecureStorage secureStorage = FlutterSecureStorage();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NHAI App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: LoadingScreen(
        authAPI: authAPI,
        secureStorage: secureStorage,
      ),
    );
  }
}
