import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This is the file you just generated!

void main() async {
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Turn on Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}