import 'package:flutter/services.dart';

class NativeSosChannel {
  static const _method = MethodChannel('com.example.frontend/sos');
  static const _events = EventChannel('com.example.frontend/sos_events');

  static Future<void> start() => _method.invokeMethod('startSos');
  static Future<void> stop() => _method.invokeMethod('stopSos');
  static Future<bool> isRunning() async =>
      await _method.invokeMethod<bool>('isRunning') ?? false;

  static Stream<String> get keywordStream =>
      _events.receiveBroadcastStream().map((e) => e.toString());
}
