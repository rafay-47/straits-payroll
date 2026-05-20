import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import mobile and web apps
import 'mobile/mobile_app.dart';
import 'web/web_app.dart';

Future<void> _bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting app initialization...');
  print('📱 Platform: ${kIsWeb ? "WEB" : "MOBILE"}');

  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: kIsWeb
          ? const FirebaseOptions(
              apiKey: "AIzaSyBkQtKU5aw14g_9rpJ9MicQ1Ck_0DqLsXo",
              authDomain: "straights-payroll.firebaseapp.com",
              projectId: "straights-payroll",
              storageBucket: "straights-payroll.firebasestorage.app",
              messagingSenderId: "900163240809",
              appId: "1:900163240809:web:46a170a572e5f714ac33f8",
              // measurementId: "G-QBB9VHQ63L"
            )
          : null,
    );
    print('✅ Firebase initialized successfully');

    print('🎨 Starting Flutter app...');
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    print('✅ App started successfully');
  } catch (e, stackTrace) {
    print('❌ Firebase initialization failed: $e');
    print('Stack trace: $stackTrace');

    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Firebase Initialization Failed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (kIsWeb) {
                        // ignore: avoid_web_libraries_in_flutter
                        // html.window.location.reload();
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload Page'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Main entry point with platform detection
void main() {
  runZonedGuarded(() {
    unawaited(_bootstrapApp());
  }, (error, stackTrace) {
    print('❌ Uncaught error in main: $error');
    print('Stack trace: $stackTrace');
  });
}

/// Root app widget with platform detection
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building MyApp widget...');
    print('📍 Platform check: kIsWeb = $kIsWeb');
    
    try {
      // Platform detection: Route to appropriate app
      final app = kIsWeb ? const WebApp() : const MobileApp();
      print('✅ App widget built successfully');
      return app;
    } catch (e, stackTrace) {
      print('❌ Error building app: $e');
      print('Stack trace: $stackTrace');
      
      // Return error screen
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Build Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
