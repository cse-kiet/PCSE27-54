import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ThreatDetectionService {
  static final ThreatDetectionService _instance = ThreatDetectionService._();
  factory ThreatDetectionService() => _instance;
  ThreatDetectionService._();

  // Threat keywords that indicate danger
  static final List<String> _threatKeywords = [
    'help',
    'bachao',
    'save me',
    'emergency',
    'danger',
    'sos',
    'scream',
    'attack',
    'rape',
    'abuse',
    'hit me',
    'stop it',
    'go away',
    'leave me alone',
    'police',
    'security',
    'someone help',
    'get away',
    'don\'t touch',
    'screaming',
    'running',
    'trapped',
    'kidnap',
    'murder',
    'hurt',
    'pain',
    'bleeding',
    'dying',
    'dead',
    'kill',
    'shot',
    'stab',
    'gun',
    'knife',
    'weapon',
    'fire',
    'flood',
    'accident',
    'crash',
    'help me',
  ];

  // Profanity/severe words that can indicate threat level
  static final List<String> _severityIndicators = [
    'screaming',
    'crying',
    'begging',
    'bleeding',
    'dying',
    'dead',
    'emergency',
    'hospital',
    'ambulance',
    'police',
    'attack',
  ];

  /// Analyzes detected text for threat level
  /// Returns a threat score from 0.0 (no threat) to 1.0 (high threat)
  double analyzeThreat(String detectedText) {
    if (detectedText.isEmpty) return 0.0;

    final textLower = detectedText.toLowerCase();
    double threatScore = 0.0;

    // Check for threat keywords
    for (final keyword in _threatKeywords) {
      if (textLower.contains(keyword)) {
        threatScore += 0.15;
      }
    }

    // Check for severe indicators (multiply threat score)
    for (final indicator in _severityIndicators) {
      if (textLower.contains(indicator)) {
        threatScore += 0.25;
      }
    }

    // Check for certain patterns
    if (textLower.contains('someone is') || textLower.contains('they are')) {
      threatScore += 0.1;
    }

    // Cap at 1.0
    threatScore = threatScore.clamp(0.0, 1.0);

    return threatScore;
  }

  /// Returns threat level as a string for logging
  String getThreatLevel(double score) {
    if (score >= 0.7) return 'CRITICAL';
    if (score >= 0.5) return 'HIGH';
    if (score >= 0.3) return 'MEDIUM';
    if (score > 0.0) return 'LOW';
    return 'NONE';
  }

  /// Determines if threat level warrants immediate action
  bool shouldTriggerAlert(double threatScore) {
    return threatScore >= 0.5; // Trigger alert if score is 0.5 or higher
  }

  /// Generates detailed alert message based on detected text and threat score
  String generateAlertMessage(String detectedText, double threatScore) {
    final level = getThreatLevel(threatScore);
    return '''🚨 THREAT DETECTED - $level PRIORITY
Detected: $detectedText
Threat Score: ${(threatScore * 100).toStringAsFixed(1)}%
Status: Sending emergency alert to contacts''';
  }

  /// Sends threat data to backend for persistent logging
  Future<bool> sendThreatReport({
    required String detectedText,
    required double threatScore,
    required String location,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/threat/report'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'detectedText': detectedText,
          'threatScore': threatScore,
          'threatLevel': getThreatLevel(threatScore),
          'location': location,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending threat report: $e');
      return false;
    }
  }
}
