import 'dart:convert';
import 'dart:ui';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _serverUrl = 'https://br0n9stj-8000.asse.devtunnels.ms/api/v1/webhook';

String? _lastProcessedKey;
DateTime? _lastProcessedTime;

@pragma('vm:entry-point')
Future<void> notificationCallback(NotificationEvent evt) async {
  await NotificationService.handleNotification(evt);
}

class NotificationService {
  static bool _initialized = false;

  static Future<void> safeInit() async {
    try {
      if (!_initialized) {
        await NotificationsListener.initialize(
          callbackHandle: notificationCallback,
        );
        _initialized = true;
      }

      final running = await NotificationsListener.isRunning ?? false;
      if (!running) {
        await NotificationsListener.startService();
      }
    } catch (_) {}
  }

  static Future<void> handleNotification(NotificationEvent evt) async {
    final now = DateTime.now();
    if (evt.isGroup == true || 
        (_lastProcessedKey == evt.key && _lastProcessedTime != null && 
         now.difference(_lastProcessedTime!).inMilliseconds < 500)) {
      return;
    }

    _lastProcessedKey = evt.key;
    _lastProcessedTime = now;

    await _sendToServer(evt);
  }

  static Future<void> _sendToServer(NotificationEvent evt) async {
    String langCode = 'vi';
    final prefs = await SharedPreferences.getInstance();

    try {
      langCode = prefs.getString('language') ?? 'vi';
    } catch (_) {}

    final dynamic rawData = evt.raw;
    final String rawContent = (rawData != null && rawData['bigText'] != null)
        ? rawData['bigText'].toString()
        : (evt.text ?? '');
    final String fullContent = rawContent.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    
    final data = {
      'user_id': 1,
      'source_app': evt.packageName,
      'content': fullContent,
      'title': evt.title ?? '',
      'language': langCode,
      'received_at': DateTime.now().toIso8601String(),
    };

    print("Sending notification data: $data");

    try {
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) return;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return;

      final responseData = decoded;
      print(  "Received response data: $responseData");

      final String? classification = responseData['classification'];

      List<String> allNotifications = prefs.getStringList('all_notifications_list') ?? [];
      allNotifications.add(jsonEncode(responseData));
      if (allNotifications.length > 100) allNotifications.removeAt(0);
      await prefs.setStringList('all_notifications_list', allNotifications);
      
      IsolateNameServer.lookupPortByName('notification')?.send(responseData);

      if (classification == 'FINANCE') {
        List<String> financeData = prefs.getStringList('finance_data_list') ?? [];
        financeData.add(jsonEncode(responseData));
        if (financeData.length > 100) financeData.removeAt(0);
        await prefs.setStringList('finance_data_list', financeData);
        
        IsolateNameServer.lookupPortByName('finance')?.send(responseData);
      } 
      else if (classification == 'SCHEDULE') {
        List<String> scheduleData = prefs.getStringList('schedule_data_list') ?? [];
        scheduleData.add(jsonEncode(responseData));
        if (scheduleData.length > 100) scheduleData.removeAt(0);
        await prefs.setStringList('schedule_data_list', scheduleData);
        
        IsolateNameServer.lookupPortByName('schedule')?.send(responseData);
      }
    } catch (_) {}
  }
}