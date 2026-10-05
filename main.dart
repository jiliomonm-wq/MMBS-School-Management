import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // If google-services.json is inside android/app, initializeApp() works automatically
    await Firebase.initializeApp();
  } catch (e) {
    // Fallback for FlutLab web/preview environments if needed
    debugPrint("Firebase init note: $e");
  }
  runApp(const SchoolApp());
}
