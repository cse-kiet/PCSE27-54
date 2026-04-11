import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'HomePage.dart';

const String _baseUrl = 'http://YOUR_BACKEND_URL';

class AuthService {
  static final _googleSignIn = GoogleSignIn();

  static Future<void> signInWithGoogle(BuildContext context) async {
    // Capture the notifier before any async gap while context is still valid
    final notifier = _LoadingNotifier.of(context);

    try {
      notifier?.value = true; // ✅ ValueNotifier uses .value, not setLoading()

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return; // finally still runs, loading will reset

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) throw Exception('Failed to get ID token');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        // ✅ Check mounted after every async gap before using context
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Authentication failed');
      }
    } catch (e) {
      // ✅ Check mounted after async gaps before using context
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      // ✅ Always resets — runs even on early return or throw
      notifier?.value = false;
    }
  }
}

class _LoadingNotifier extends InheritedNotifier<ValueNotifier<bool>> {
  const _LoadingNotifier({
    required super.notifier,
    required super.child,
  });

  static ValueNotifier<bool>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LoadingNotifier>()?.notifier;
}

class AuthLoadingWrapper extends StatefulWidget {
  final Widget child;
  const AuthLoadingWrapper({super.key, required this.child});

  @override
  State<AuthLoadingWrapper> createState() => _AuthLoadingWrapperState();
}

class _AuthLoadingWrapperState extends State<AuthLoadingWrapper> {
  final ValueNotifier<bool> _loading = ValueNotifier(false);

  @override
  void dispose() {
    _loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LoadingNotifier(
      notifier: _loading,
      child: ValueListenableBuilder<bool>(
        valueListenable: _loading,
        builder: (context, isLoading, child) {
          return Stack(
            children: [
              child!,
              if (isLoading)
                const Opacity(
                  opacity: 0.6,
                  child: ModalBarrier(dismissible: false, color: Colors.black),
                ),
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE91E8C)),
                ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}