import "package:flutter/material.dart";
import "login_page.dart";
import "dart:async";

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState(); // Fixed state name convention
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // 2. Setup 3-second Timer
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AdminLoginPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Logo section
            Padding(
              padding: const EdgeInsets.only(top: 80, bottom: 8), // Adjusted for status bar
              child: Center(
                child: Image.asset(
                  "assets/images/logo.png",
                  width: MediaQuery.of(context).size.width * 0.72,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // "Powered by" text
            const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.black54),
                children: [
                  TextSpan(
                    text: "powered by ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: "HAPPY TAILS VETERINARY CLINIC",
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),

            // Pet image fills the bottom
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  "assets/images/splashscreen1.jpg",
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover, // Changed to cover to prevent white gaps
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}