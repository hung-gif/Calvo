import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_provider.dart';
import '../services/briefing_service.dart';

class MobileOverviewScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigate;

  const MobileOverviewScreen({super.key, this.onNavigate});

  @override
  State<MobileOverviewScreen> createState() => MobileOverviewScreenState();
}

class MobileOverviewScreenState extends State<MobileOverviewScreen> {
  double balance = 0.0;
  String currency = 'đ';
  int importantNotifs = 0;
  int spamNotifs = 0;
  int pendingTasks = 0;
  String scheduleSummary = "";
  String dailySummary = "";

  final ReceivePort _overviewPort = ReceivePort();

  bool briefingEnabled = true;
  TimeOfDay briefingTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  void initState() {
    super.initState();
    _setupBriefingListener();
    _loadBriefingSettings().then((_) => refreshAllData());
  }

  Future<void> _toggleBriefing(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      briefingEnabled = value;
    });

    await prefs.setBool('brief_enabled', briefingEnabled);

    if (briefingEnabled) {
      await BriefingService.scheduleNextBriefing(
        hour: briefingTime.hour,
        minute: briefingTime.minute,
      );
    } else {
      await BriefingService.cancelBriefing();
    }
  }

  Future<void> _pickBriefingTime() async {
  final picked = await showTimePicker(
    context: context,
    initialTime: briefingTime,
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: false,
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    setState(() {
      briefingTime = picked;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('brief_hour', picked.hour);
    await prefs.setInt('brief_minute', picked.minute);

    if (briefingEnabled) {
      await BriefingService.scheduleNextBriefing(
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }
}

  String _formatTime(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _loadBriefingSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = prefs.getBool('brief_enabled') ?? true;
    final hour = prefs.getInt('brief_hour') ?? 22;
    final minute = prefs.getInt('brief_minute') ?? 0;

    if (!mounted) return;

    setState(() {
      briefingEnabled = enabled;
      briefingTime = TimeOfDay(hour: hour, minute: minute);
    });

    if (enabled) {
      await BriefingService.scheduleNextBriefing(hour: hour, minute: minute);
    } else {
      await BriefingService.cancelBriefing();
    }
  }

  void _setupBriefingListener() {
    IsolateNameServer.removePortNameMapping('overview');
    IsolateNameServer.registerPortWithName(_overviewPort.sendPort, 'overview');

    _overviewPort.listen((message) {
      if (message is Map && message['type'] == 'DAILY_REPORT') {
        if (mounted) {
          setState(() {
            dailySummary = (message['data'] ?? "").toString();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('overview');
    _overviewPort.close();
    super.dispose();
  }

  Future<void> refreshAllData() async {
  final prefs = await SharedPreferences.getInstance();
  if (!mounted) return;

  final cached = prefs.getString('ov_daily_report') ?? "";

  setState(() {
    balance = prefs.getDouble('user_balance') ?? 0.0;
    currency = prefs.getString('user_currency') ?? 'đ';
    importantNotifs = prefs.getInt('ov_notif_important') ?? 0;
    spamNotifs = prefs.getInt('ov_notif_spam') ?? 0;
    pendingTasks = prefs.getInt('ov_tasks_pending') ?? 0;
    scheduleSummary = prefs.getString('ov_schedule_summary') ?? "";

    if (dailySummary.isEmpty && cached.isNotEmpty) {
      dailySummary = cached;
    }
  });
}


  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = userProvider.isDarkMode;
    final Color primaryColor = userProvider.primaryColor;
    String t(String key) => userProvider.getText(key);

    final gradientColors = isDark
        ? [const Color(0xFF000000), const Color(0xFF0F0C29), const Color(0xFF24243E)]
        : [const Color(0xFFFDFBFB), const Color(0xFFEBEDEE)];

    final glowColor1 = primaryColor.withOpacity(isDark ? 0.3 : 0.15);
    final glowColor2 =
        isDark ? Colors.blueAccent.withOpacity(0.2) : Colors.pinkAccent.withOpacity(0.1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: refreshAllData,
        color: primaryColor,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
            ),
            Positioned(top: -100, left: -50, child: _buildGlowCircle(300, glowColor1)),
            Positioned(bottom: -50, right: -50, child: _buildGlowCircle(250, glowColor2)),
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildBriefingCard(
                    t,
                    isDark,
                    primaryColor,
                    dailySummary,
                    briefingEnabled: briefingEnabled,
                    briefingTime: briefingTime,
                    onPickTime: _pickBriefingTime,
                    onToggle: _toggleBriefing,
                  ),
                  const SizedBox(height: 16),
                  _buildQuickStatsGrid(t, isDark, importantNotifs, balance, pendingTasks),
                  const SizedBox(height: 16),
                  _buildNotificationSummary(t, isDark, primaryColor, importantNotifs, spamNotifs),
                  const SizedBox(height: 16),
                  _buildScheduleSummary(t, isDark, pendingTasks, scheduleSummary),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSmallChip(String label, Color color, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (color == Colors.red) BoxShadow(color: color.withOpacity(0.3), blurRadius: 4),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGlowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  BoxDecoration _glassDecoration(bool isDark, {Color? borderColor}) {
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? (isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4)),
        width: 1,
      ),
    );
  }

  Widget _buildQuickStatsGrid(Function t, bool isDark, int important, double balance, int tasks) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.notifications_none,
          iconColor: Colors.orange,
          value: "$important",
          label: t('stat_important'),
          onTap: () => widget.onNavigate?.call(3),
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: Colors.green,
          value: "${(balance / 1000).toStringAsFixed(2)}K",
          label: t('stat_balance'),
          onTap: () => widget.onNavigate?.call(1),
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.calendar_today_outlined,
          iconColor: Colors.blue,
          value: "$tasks",
          label: t('stat_tasks'),
          onTap: () => widget.onNavigate?.call(2),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: _glassDecoration(isDark),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSummary(Function t, bool isDark, Color primaryColor, int important, int spam) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                t('sect_notif'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            important > 0
                ? "${t('ov_notif_important_msg')} $important ${t('ov_notif_important_suffix')}"
                : t('ov_notif_stable_msg'),
            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSmallChip("$important ${t('chip_important')}", Colors.red),
              const SizedBox(width: 8),
              _buildSmallChip(
                "$spam ${t('chip_spam')}",
                isDark ? Colors.white10 : Colors.grey[300]!,
                textColor: isDark ? Colors.white70 : Colors.black54,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSummary(Function t, bool isDark, int pending, String summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                t('sect_schedule'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.isNotEmpty ? summary : t('no_task'),
            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], height: 1.4, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBriefingCard(
    Function t,
    bool isDark,
    Color primaryColor,
    String dailySummary, {
    required bool briefingEnabled,
    required TimeOfDay briefingTime,
    required VoidCallback onPickTime,
    required ValueChanged<bool> onToggle,
  }) {
    final bgColor = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06);
    final titleColor = isDark ? Colors.white.withOpacity(0.92) : Colors.black.withOpacity(0.88);
    final bodyColor = isDark ? Colors.white.withOpacity(0.72) : Colors.black.withOpacity(0.70);
    final shadowColor = isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.06);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: InkWell(
        key: ValueKey(dailySummary),
        borderRadius: BorderRadius.circular(24),
        onTap: onPickTime,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(color: shadowColor, blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(isDark ? 0.12 : 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t('daily_briefing_title'),
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: briefingEnabled,
                    onChanged: onToggle,
                    activeColor: primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: primaryColor.withOpacity(isDark ? 0.9 : 0.8)),
                  const SizedBox(width: 8),
                  Text(
                    "${t('time')}: ${_formatTime(briefingTime)}",
                    style: TextStyle(color: bodyColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onPickTime,
                    child: Text(t('change_time'), style: TextStyle(color: primaryColor)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Opacity(
                opacity: briefingEnabled ? 1.0 : 0.5,
                child: Text(
                  dailySummary.isEmpty ? t('no_briefing_yet') : dailySummary,
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: 15,
                    height: 1.6,
                    fontStyle: dailySummary.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                  softWrap: true,
                ),
              ),
              if (dailySummary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    t('updated_just_now'),
                    style: TextStyle(color: primaryColor.withOpacity(isDark ? 0.55 : 0.70), fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
