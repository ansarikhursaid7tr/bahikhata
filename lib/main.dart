import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Persistence
  if (kIsWeb) {
    // Android PWAs (WebAPKs) do NOT clear sessionStorage when swiped away.
    // Persistence.NONE is the ONLY way to guarantee a logout on Android.
    // (This has zero effect on the app updating/caching!)
    await FirebaseAuth.instance.setPersistence(Persistence.NONE);
  }

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    const ProviderScope(
      child: BahiKhataApp(),
    ),
  );
}
