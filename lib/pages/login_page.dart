import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Core UI & Utility Imports (shared with user app)
import '../core/widgets/app_text_field.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_logo.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/validators.dart';
import '../core/utils/error_handler.dart';

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
    // ── Same visual structure as the user LoginPage ────────────────────────
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Header Row – back button + logo
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Spacer(),
                  const AppLogo(width: 250),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),

              const Spacer(),

              // Email field with decorative cat image (same as user login)
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  AppTextField(
                    controller: _emailController,
                    hint: 'Email',
                    isRounded: false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  Positioned(
                    bottom: -30,
                    child: Image.asset(
                      'assets/images/c1-removebg-preview.png',
                      width: 350,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              AppTextField(
                controller: _passwordController,
                hint: 'Password',
                obscureText: true,
                isRounded: false,
              ),

              const SizedBox(height: 40),

              AppButton(
                text: 'LOGIN',
                isLoading: _isLoading,
                onPressed: _handleAdminLogin,
              ),

              const SizedBox(height: 20),

              // Small label so staff know this is the admin portal
              Text(
                'Admin Portal',
                style: AppTextStyles.h1.copyWith(
                  fontSize: 12,
                  color: Colors.black38,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Login handler following the blueprint gatekeeper logic ─────────────
  Future<void> _handleAdminLogin() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final emailError = Validators.validateEmail(email);
    if (emailError != null) { _showError(emailError); return; }

    final passError = Validators.validateRequired(password, 'Password');
    if (passError != null) { _showError(passError); return; }

    setState(() => _isLoading = true);

    try {
      // Step 1 – Firebase Auth verification
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // Step 2 – Query the 'admins' collection for role
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (!adminDoc.exists) {
        // UID not in admins collection → force logout
        await FirebaseAuth.instance.signOut();
        _showError('Unauthorized Access: This account has no admin privileges.');
        return;
      }

      final data = adminDoc.data() as Map<String, dynamic>;
      final String role = data['role'] ?? '';

      // Step 3 – Role-based routing
      if (role == 'super_admin') {
        Navigator.pushNamedAndRemoveUntil(context, '/super_admin', (_) => false);
      } else if (role == 'staff_admin') {
        Navigator.pushNamedAndRemoveUntil(context, '/staff_admin', (_) => false);
      } else {
        await FirebaseAuth.instance.signOut();
        _showError('Unauthorized Access: Unknown role assigned to this account.');
      }
    } catch (e) {
      if (mounted) _showError(ErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
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