import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_manager.dart';
import 'HomePage.dart';
import 'LoginPage.dart';

class AuthService {
  static Future<void> login({
    required BuildContext context,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception(
          'Connection timed out.\nMake sure your phone and PC are on the same WiFi.'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      await SessionManager.saveSession(
        token: data['token'],
        user: Map<String, dynamic>.from(data['user']),
      );
      if (context.mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  static Future<void> register({
    required BuildContext context,
    required String name,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email}),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception(
          'Connection timed out.\nMake sure your phone and PC are on the same WiFi.'),
    );

    final data = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      await SessionManager.saveSession(
        token: data['token'],
        user: Map<String, dynamic>.from(data['user']),
      );
      if (context.mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  static Future<void> signOut(BuildContext context) async {
    await SessionManager.clearSession();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }
}

// Kept for any other screens that may use it
class AuthLoadingWrapper extends StatelessWidget {
  final Widget child;
  const AuthLoadingWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
