import 'dart:convert';
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _serverUrl = "https://br0n9stj-8000.asse.devtunnels.ms/";

  static Future<void> init() async {
    try {
    
    await NotificationsListener.initialize(callbackHandle: _onNotificationReceived);
    print("✅ Notification Listener initialize successfuly");
  } catch (e) {
    print("❌ Error NotificationsListener.initialize: $e");
  }}
  

  @pragma('vm:entry-point')
  static void _onNotificationReceived(NotificationEvent evt) async {
    try {
      await _sendToServer(evt);
    } catch (e) {
      print(e);
    }
  }

  static Future<void> _sendToServer(NotificationEvent evt) async {
    String langCode = 'vi';
    try {
      final prefs = await SharedPreferences.getInstance();
      langCode = prefs.getString('language_code') ?? 'vi';
    } catch (e) {
      print("⚠️ SharedPreferences error (default 'vi'): $e");
    }

    final data = {
      "package": evt.packageName,
      "title": evt.title,
      "body": evt.text,
      "timestamp": evt.createAt.toString(),
      "language": langCode,
    };

    try {
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));

        print("📥 Response data: $responseData");

    if (responseData.containsKey('type_of_transaction')) {
          final SendPort? port = IsolateNameServer.lookupPortByName('update_finance_ui');
          port?.send(responseData);
        } 
        else if (responseData.containsKey('event_name') || responseData.containsKey('start_time')) {
          final SendPort? port = IsolateNameServer.lookupPortByName('update_schedule_ui');
          port?.send(responseData);
        } 
        else {
          final SendPort? port = IsolateNameServer.lookupPortByName('update_notification_ui');
          port?.send(responseData);
        }
      } else {
        print("❌ Server Error (Code ${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      print("❌ Connection error: $e");
    }
  }
}