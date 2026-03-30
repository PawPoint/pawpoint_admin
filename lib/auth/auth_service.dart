import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = 'http://localhost:8000';

  /// Sign up via backend API, then sign in locally with the custom token
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'name': name,
        'phone': phone,
        'address': address,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Sign in locally with the custom token returned by the backend
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        final credential = await FirebaseAuth.instance.signInWithCustomToken(
          token,
        );
        return credential.user;
      }
      return null;
    } else {
      // Extract error message from backend response
      final detail = data['detail'] ?? 'Registration failed. Please try again.';
      throw Exception(detail);
    }
  }

  /// Login via backend API, then sign in locally with email/password
  /// (We still need local sign-in for Firebase SDK features like currentUser)
  Future<User?> login({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Backend verified credentials — now sign in locally
      // so FirebaseAuth.instance.currentUser works throughout the app
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } else {
      final detail = data['detail'] ?? 'Login failed. Please try again.';
      throw Exception(detail);
    }
  }
}
