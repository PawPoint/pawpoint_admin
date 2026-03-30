import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class StaffAdminDashboard extends StatelessWidget {
  const StaffAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("STAFF PANEL"),
        backgroundColor: Colors.orangeAccent, // Different color to distinguish roles
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_ind, size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 20),
            Text("Welcome, Staff Admin", style: AppTextStyles.h1),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "You have access to manage daily operations and appointments.",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}