import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawpoint_admin/pages/login_page.dart';
import 'package:pawpoint_admin/pages/splash_screen.dart';
import 'package:pawpoint_admin/pages/superadmin_dashboard.dart';
import 'package:pawpoint_admin/pages/staffadmin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawPoint Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      // Define the starting page
      initialRoute: '/',
      
      // Define all possible screens here
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const AdminLoginPage(),
        '/super_admin': (context) => const SuperAdminDashboard(),
        '/staff_admin': (context) => const StaffAdminDashboard(),
      },
    );
  }
}