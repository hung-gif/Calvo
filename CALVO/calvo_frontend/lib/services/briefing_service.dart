import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class BriefingService {
  static const String _url =
      'https://br0n9stj-8000.asse.devtunnels.ms/api/v1/mobile/briefing';

  static const String taskId = "fetch_daily_report";

  static const String taskNowName = "com.calvo.daily_briefing_now";
  static const String taskNextName = "com.calvo.daily_briefing_next";

  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> scheduleNextBriefing({int hour = 22, int minute = 0}) async {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    var delay = scheduled.difference(now);

    if (delay.inSeconds < 30) {
      scheduled = scheduled.add(const Duration(days: 1));
      delay = scheduled.difference(now);
    }

    await Workmanager().cancelByUniqueName(taskNextName);

    await Workmanager().registerOneOffTask(
      taskNextName,
      taskId,
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 10),
    );

    debugPrint("✅ Scheduled briefing at $scheduled (delay: ${delay.inMinutes}m)");
  }

  static Future<void> runNow() async {
    await Workmanager().cancelByUniqueName(taskNowName);
    await Workmanager().registerOneOffTask(
      taskNowName,
      taskId,
      initialDelay: Duration.zero,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> cancelBriefing() async {
    await Workmanager().cancelByUniqueName(taskNowName);
    await Workmanager().cancelByUniqueName(taskNextName);
  }

  static Future<void> fetchAndDispatchReport() async {
    debugPrint("🚀 Briefing task started");
    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': 1}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final String reportFromServer = decoded['report'] ?? "";

        if (reportFromServer.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('ov_daily_report', reportFromServer);

          final SendPort? overviewPort =
              IsolateNameServer.lookupPortByName('overview');
          overviewPort?.send({
            'type': 'DAILY_REPORT',
            'data': reportFromServer,
          });
        }
      } else {
        debugPrint("❌ Briefing HTTP ${response.statusCode}");
      }
    } catch (e, st) {
      debugPrint("❌ Briefing error: $e");
      debugPrint("$st");
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await BriefingService.fetchAndDispatchReport();

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('brief_enabled') ?? true;
    final hour = prefs.getInt('brief_hour') ?? 22;
    final minute = prefs.getInt('brief_minute') ?? 0;

    if (enabled) {
      await BriefingService.scheduleNextBriefing(hour: hour, minute: minute);
    } else {
      await BriefingService.cancelBriefing();
    }

    return true;
  });
}
