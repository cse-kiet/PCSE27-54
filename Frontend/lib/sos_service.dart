import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<Map<String, double>?> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
      return {'lat': pos.latitude, 'lng': pos.longitude};
    } catch (_) {
      return null;
    }
  }

  Future<bool> sendSosAlert(String message) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return false;

      final location = await _getLocation();

      final response = await http.post(
        Uri.parse(ApiConfig.sendSos),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          if (location != null) 'lat': location['lat'],
          if (location != null) 'lng': location['lng'],
        }),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('SOS send error: $e');
      return false;
    }
  }
}
