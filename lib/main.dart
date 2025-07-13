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

  final double aspectRatio = 9 / 16;
  final double minWidth = 360;
  final double minHeight = 640;

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NHAI App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
        pageTransitionsTheme: kIsWeb
            ? const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: NoTransitionsBuilder(),
                  TargetPlatform.iOS: NoTransitionsBuilder(),
                  TargetPlatform.macOS: NoTransitionsBuilder(),
                  TargetPlatform.linux: NoTransitionsBuilder(),
                  TargetPlatform.windows: NoTransitionsBuilder(),
                },
              )
            : const PageTransitionsTheme(),
      ),
      home: LoadingScreen(
        authAPI: authAPI,
        secureStorage: secureStorage,
      ),
    );

    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          double targetWidth = screenWidth;
          double targetHeight = screenWidth / aspectRatio;

          if (targetHeight > screenHeight) {
            targetHeight = screenHeight;
            targetWidth = screenHeight * aspectRatio;
          }

          targetWidth = targetWidth < minWidth ? minWidth : targetWidth;
          targetHeight = targetHeight < minHeight ? minHeight : targetHeight;

          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
            ),
            child: Center(
              child: Container(
                width: targetWidth,
                height: targetHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    spreadRadius: 2,
                    blurRadius: 30,
                  )
                ]),
                child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: Size(targetWidth, targetHeight),
                    ),
                    child: app),
              ),
            ),
          );
        },
      );
    }

    return app;
  }
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
