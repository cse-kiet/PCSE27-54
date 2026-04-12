import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'sos_service.dart';
import 'threat_detection_service.dart';

// Entry point for the background isolate — must be a top-level function
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SosTaskHandler());
}

class SosTaskHandler extends TaskHandler {
  final _sosService = SosService();
  final _threatDetection = ThreatDetectionService();
  bool _alertSent = false;
  DateTime? _lastAlertTime;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _alertSent = false;
    _lastAlertTime = null;
    _startListening();
  }

  void _startListening() {
    _sosService.startListening(
      onKeywordDetected: () async {
        // Prevent alert spam - only one alert per 30 seconds
        if (_alertSent) return;
        if (_lastAlertTime != null && 
            DateTime.now().difference(_lastAlertTime!).inSeconds < 30) {
          return;
        }

        _alertSent = true;
        _lastAlertTime = DateTime.now();

        // Send SOS alert to backend (which will email contacts)
        await _sosService.sendSosAlert(
          '🚨 SOS ALERT! A distress keyword was detected. I need immediate help!',
        );

        // Reset so it can detect again after a delay
        await Future.delayed(const Duration(seconds: 30));
        _alertSent = false;
        _startListening();
      },
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Restart listening if it stopped (e.g. after a phone call)
    if (!_sosService.isListening) {
      _startListening();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _sosService.stopListening();
  }
}
