import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_manager.dart';

const _keywords = ['help', 'bachao', 'save me', 'emergency', 'danger', 'sos'];

class SosService {
  static final SosService _instance = SosService._();
  factory SosService() => _instance;
  SosService._();

  final _stt = SpeechToText();
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<void> startListening({required VoidCallback onKeywordDetected}) async {
    if (_isListening) return;
    final available = await _stt.initialize(
      onError: (_) => stopListening(),
    );
    if (!available) return;

    _isListening = true;
    _stt.listen(
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 5),
      onResult: (result) {
        final words = result.recognizedWords.toLowerCase();
        if (_keywords.any((k) => words.contains(k))) {
          onKeywordDetected();
        }
      },
    );
  }

  void stopListening() {
    _stt.stop();
    _isListening = false;
  }

  /// Calls the backend which sends SMS to all trusted contacts via Fast2SMS.
  Future<void> sendSosAlert(String message) async {
    final token = await SessionManager.getToken();
    if (token == null) return;

    await http.post(
      Uri.parse(ApiConfig.sendSos),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': message}),
    );
  }
}
