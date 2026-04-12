import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_manager.dart';
import 'threat_detection_service.dart';

const _keywords = ['help', 'bachao', 'save me', 'emergency', 'danger', 'sos'];

class SosService {
  static final SosService _instance = SosService._();
  factory SosService() => _instance;
  SosService._();

  final _stt = SpeechToText();
  final _threatDetection = ThreatDetectionService();
  bool _isListening = false;
  VoidCallback? _onKeywordDetected;

  bool get isListening => _isListening;

  /// Starts listening for voice input continuously
  /// [continuousMode] - if true, will retry listening if connection drops
  /// [onKeywordDetected] - callback when distress keyword or threat is detected
  Future<void> startListening({
    required VoidCallback onKeywordDetected,
    bool continuousMode = true,
  }) async {
    if (_isListening) return;
    
    _onKeywordDetected = onKeywordDetected;

    try {
      final available = await _stt.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          if (continuousMode && _isListening) {
            // Restart listening after error
            Future.delayed(const Duration(seconds: 2), _restartListening);
          }
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
        },
      );

      if (!available) {
        debugPrint('Speech recognition not available');
        return;
      }

      _isListening = true;
      _startVoiceDetection(continuousMode);
    } catch (e) {
      debugPrint('Error initializing speech to text: $e');
      _isListening = false;
    }
  }

  /// Internal method to start voice detection with continuous listening
  void _startVoiceDetection(bool continuousMode) {
    _stt.listen(
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      onResult: (result) {
        final words = result.recognizedWords.toLowerCase();

        debugPrint('Detected text: $words');

        // Check for threat keywords
        bool hasKeyword = _keywords.any((k) => words.contains(k));

        // Analyze threat level
        final threatScore = _threatDetection.analyzeThreat(words);
        final isThreat = _threatDetection.shouldTriggerAlert(threatScore);

        if (hasKeyword || isThreat) {
          debugPrint('Keyword or threat detected: keyword=$hasKeyword, threat=$isThreat (score=$threatScore)');
          _onKeywordDetected?.call();
        }

        // If listening finished and continuous mode enabled, restart
        if (result.finalResult && continuousMode && _isListening) {
          Future.delayed(const Duration(milliseconds: 500), _restartListening);
        }
      },
    );
  }

  /// Restarts voice listening (for continuous monitoring)
  void _restartListening() {
    if (_isListening) {
      _stt.stop();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isListening) {
          _startVoiceDetection(true);
        }
      });
    }
  }

  void stopListening() {
    _stt.stop();
    _isListening = false;
    _onKeywordDetected = null;
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
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Sends SOS alert through backend (triggers email to contacts)
  Future<bool> sendSosAlert(String message) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        debugPrint('No auth token available');
        return false;
      }

      final location = await _getLocation();
      final locationStr = location != null 
          ? '${location['lat']},${location['lng']}'
          : 'Unknown';

      debugPrint('Sending SOS alert: $message with location: $locationStr');

      final response = await http.post(
        Uri.parse(ApiConfig.sendSos),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'alertType': 'VOICE_DETECTED',
          if (location != null) 'lat': location['lat'],
          if (location != null) 'lng': location['lng'],
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      } else {
        debugPrint('SOS alert failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('SOS send error: $e');
      return false;
    }
  }

  /// Sends threat-specific alert to backend (includes threat analysis)
  Future<bool> sendThreatAlert({
    required String detectedText,
    required double threatScore,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return false;

      final location = await _getLocation();
      final threatLevel = _threatDetection.getThreatLevel(threatScore);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/threat/alert'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'detectedText': detectedText,
          'threatScore': threatScore,
          'threatLevel': threatLevel,
          'alertType': 'VOICE_THREAT',
          if (location != null) 'lat': location['lat'],
          if (location != null) 'lng': location['lng'],
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Threat alert send error: $e');
      return false;
    }
  }
}
