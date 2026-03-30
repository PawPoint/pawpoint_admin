import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/staffadmin_dashboard.dart'; 
import '../pages/superadmin_dashboard.dart';

// Core UI & Utility Imports (based on your structure)
import 'package:pawpoint_admin/auth/auth_service.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/error_handler.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Header Row with Back Button and Logo
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const AppLogo(width: 250),
                  const Spacer(),
                  const SizedBox(width: 48), // Balances the back button width
                ],
              ),
              
              const Spacer(),
              
              // Admin Portal Label
              Text(
                "ADMIN PORTAL",
                style: AppTextStyles.h1.copyWith(
                  letterSpacing: 2,
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Email Field with the overlaying Image
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  AppTextField(
                    controller: _emailController,
                    hint: "Admin Email",
                    isRounded: false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  Positioned(
                    bottom: -30,
                    child: Image.asset(
                      "assets/images/c1.png",
                      width: 350,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 15),
              
              // Password Field
              AppTextField(
                controller: _passwordController,
                hint: "Admin Password",
                obscureText: true,
                isRounded: false,
              ),
              
              const SizedBox(height: 40),
              
              // Login Button
              AppButton(
                text: "ADMIN LOGIN",
                isLoading: _isLoading,
                onPressed: _handleAdminLogin,
              ),
              
              // Spacer at the bottom to keep layout centered
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  /// Logic to handle Admin Login and Role-based Redirection
  Future<void> _handleAdminLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Basic Validation
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      _showErrorSnackBar(emailError);
      return;
    }

    final passwordError = Validators.validateRequired(password, "Password");
    if (passwordError != null) {
      _showErrorSnackBar(passwordError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Firebase Auth Login
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // 3. Fetch Role from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        throw Exception("Account data not found in system.");
      }

      // Extract the role from the document
      final data = userDoc.data() as Map<String, dynamic>;
      final String role = data['role'] ?? '';

      if (!mounted) return;

      // 4. Conditional Navigation
        if (role == 'super_admin') {
          // Clears all previous screens and goes to Super Admin
          Navigator.pushNamedAndRemoveUntil(context, '/super_admin', (route) => false);
        } else if (role == 'staff_admin') {
          // Clears all previous screens and goes to Staff Admin
          Navigator.pushNamedAndRemoveUntil(context, '/staff_admin', (route) => false);
        } else {
          // If they are a regular user or have no admin role, log them out
          await FirebaseAuth.instance.signOut();
          _showErrorSnackBar("Access Denied: You do not have admin privileges.");
        }

    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Helper to clear stack and navigate
  void _navigateToDashboard(Widget dashboard) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => dashboard),
      (route) => false,
    );
  }

  /// Reusable Error SnackBar matching your app style
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}