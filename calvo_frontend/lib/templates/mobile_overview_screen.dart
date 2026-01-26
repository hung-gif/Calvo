import 'dart:ui'; // Cần cho BackdropFilter
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import '../../shared/models/overview_data.dart';

class MobileOverviewScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigate;

  const MobileOverviewScreen({super.key, this.onNavigate});

  @override
  State<MobileOverviewScreen> createState() => _MobileOverviewScreenState();
}

class _MobileOverviewScreenState extends State<MobileOverviewScreen> {
  // Mock data (Giả lập dữ liệu)
  final data = OverviewData.mock;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ Provider
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = userProvider.isDarkMode;
    final primaryColor = userProvider.primaryColor;
    String t(String key) => userProvider.getText(key);

    // --- CẤU HÌNH MÀU SẮC ---
    final gradientColors = isDark 
        ? [const Color(0xFF000000), const Color(0xFF0F0C29), const Color(0xFF24243E)] 
        : [const Color(0xFFFDFBFB), const Color(0xFFEBEDEE)];
    
    final glowColor1 = isDark ? primaryColor.withOpacity(0.3) : primaryColor.withOpacity(0.15); 
    final glowColor2 = isDark ? Colors.blueAccent.withOpacity(0.2) : Colors.pinkAccent.withOpacity(0.1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. NỀN GRADIENT
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),
          
          // 2. HIỆU ỨNG GLOW (ĐỐM SÁNG)
          Positioned(
            top: -100, left: -50,
            child: _buildGlowCircle(300, glowColor1),
          ),
          Positioned(
            bottom: -50, right: -50,
            child: _buildGlowCircle(250, glowColor2),
          ),

          // 3. NỘI DUNG CHÍNH (SCROLLABLE)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildAISummaryCard(t, isDark, primaryColor),
                const SizedBox(height: 16),
                _buildQuickStatsGrid(t, isDark),
                const SizedBox(height: 16),
                _buildNotificationSummary(t, isDark, primaryColor),
                const SizedBox(height: 16),
                _buildFinanceSummary(t, isDark),
                const SizedBox(height: 16),
                _buildScheduleSummary(t, isDark),
                const SizedBox(height: 80), // Padding đáy để tránh bị che
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CÁC WIDGET CON (UI COMPONENTS) ---

  Widget _buildGlowCircle(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), 
        child: Container(color: Colors.transparent)
      ),
    );
  }

  // Helper tạo khung kính (Glassmorphism)
  BoxDecoration _glassDecoration(bool isDark, {Color? borderColor}) {
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? (isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4)), 
        width: 1
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1), 
          blurRadius: 10, 
          offset: const Offset(0, 4)
        )
      ],
    );
  }

  // 1. AI Summary
  Widget _buildAISummaryCard(Function t, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassDecoration(isDark, 
        borderColor: isDark ? primaryColor.withOpacity(0.5) : primaryColor.withOpacity(0.3),
      ).copyWith(
        gradient: isDark ? null : LinearGradient(
          colors: [primaryColor.withOpacity(0.1), Colors.white.withOpacity(0.4)]
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🤖", style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('ai_summary_title'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  "Chào buổi sáng! Hôm nay bạn có ${data.schedule.totalTasks} công việc. Tôi đã lọc ${data.notifications.spam} tin rác.",
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[800], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Quick Stats Grid
  Widget _buildQuickStatsGrid(Function t, bool isDark) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.notifications_none, iconColor: Colors.orange,
          value: "${data.notifications.important}", label: t('stat_important'),
          onTap: () => widget.onNavigate?.call(3), isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.account_balance_wallet_outlined, iconColor: Colors.green,
          value: "${(data.finance.balance / 1000000).toStringAsFixed(1)}M", label: t('stat_balance'),
          onTap: () => widget.onNavigate?.call(1), isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.calendar_today_outlined, iconColor: Colors.blue,
          value: "${data.schedule.upcoming}", label: t('stat_tasks'),
          onTap: () => widget.onNavigate?.call(2), isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon, required Color iconColor, required String value, 
    required String label, required VoidCallback onTap, required bool isDark
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
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : iconColor)),
              Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Notification Summary
  Widget _buildNotificationSummary(Function t, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.notifications, color: primaryColor, size: 20), 
            const SizedBox(width: 8), 
            Text(t('sect_notif'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black))
          ]),
          const SizedBox(height: 12),
          Text(data.notifications.summary, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700])),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(
                label: Text("${data.notifications.important} ${t('chip_important')}", style: const TextStyle(color: Colors.white, fontSize: 12)), 
                backgroundColor: Colors.red, side: BorderSide.none
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text("${data.notifications.spam} ${t('chip_spam')}", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black)), 
                backgroundColor: isDark ? Colors.white10 : Colors.grey[200], 
                side: BorderSide.none
              ),
            ],
          )
        ],
      ),
    );
  }

  // 4. Finance Summary
  Widget _buildFinanceSummary(Function t, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(t('sect_finance'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          const SizedBox(height: 8),
          Text(data.finance.summary, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 14)),
          const SizedBox(height: 12),
          
          _buildFinanceButton(
            label: t('label_income'), amount: data.finance.todayIncome, color: Colors.green, isIncome: true,
            onTap: () => _showFluctuationDialog(t, isDark), isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildFinanceButton(
            label: t('label_expense'), amount: data.finance.todayExpense, color: Colors.red, isIncome: false,
            onTap: () => _showFluctuationDialog(t, isDark), isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceButton({
    required String label, required double amount, required Color color, 
    required bool isIncome, required VoidCallback onTap, required bool isDark
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: isDark ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(isIncome ? Icons.trending_up : Icons.trending_down, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : color)),
            ]),
            Text(
              "${isIncome ? '+' : '-'}${currencyFormatter.format(amount)}",
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Schedule Summary
  Widget _buildScheduleSummary(Function t, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassDecoration(isDark),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.calendar_today, color: Colors.blue, size: 20), 
            const SizedBox(width: 8), 
            Text(t('sect_schedule'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black))
          ]),
          const SizedBox(height: 12),
          Text(data.schedule.summary, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700])),
          const SizedBox(height: 12),
          _buildScheduleItem("Review code PR #234", "9:00 - 10:00 • Đã xong", true, isDark),
          _buildScheduleItem("Họp team Sprint Planning", "14:00 - 15:30 • Sắp tới", false, isDark),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String title, String time, bool isDone, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone 
            ? (isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50) 
            : (isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50), 
        border: Border(left: BorderSide(color: isDone ? Colors.green : Colors.blue, width: 4)), 
        borderRadius: BorderRadius.circular(4)
      ),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.calendar_today, size: 16, color: isDone ? Colors.green : Colors.blue),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w500, decoration: isDone ? TextDecoration.lineThrough : null, color: isDark ? Colors.white : Colors.black)),
              Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  // --- DIALOG & CHART ---

  void _showFluctuationDialog(Function t, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t('dialog_finance_title'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
                  IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(height: 200, child: _buildLineChart(isDark)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDialogSummaryBox(t('total_income'), "+5.000.000đ", Colors.green, isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDialogSummaryBox(t('total_expense'), "-350.000đ", Colors.red, isDark)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogSummaryBox(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1), 
        borderRadius: BorderRadius.circular(8),
        border: isDark ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // Widget LineChart (Đã sửa lỗi color dòng 333)
  Widget _buildLineChart(bool isDark) {
    final axisColor = isDark ? Colors.white70 : Colors.black54;
    final gridColor = isDark ? Colors.white10 : Colors.grey[300]!;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: false, 
          getDrawingHorizontalLine: (value) => FlLine(color: gridColor, strokeWidth: 1)
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            switch (value.toInt()) {
              case 0: return Text('0h', style: TextStyle(fontSize: 10, color: axisColor));
              case 6: return Text('6h', style: TextStyle(fontSize: 10, color: axisColor));
              case 12: return Text('12h', style: TextStyle(fontSize: 10, color: axisColor));
              case 18: return Text('18h', style: TextStyle(fontSize: 10, color: axisColor));
            }
            return const SizedBox();
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // FIX LỖI COLOR TẠI ĐÂY: Dùng color (số ít), không dùng colors (số nhiều)
          LineChartBarData(
            spots: const [FlSpot(0, 0), FlSpot(6, 0), FlSpot(12, 1.5), FlSpot(18, 3.3), FlSpot(24, 3.5)],
            isCurved: true,
            color: Colors.redAccent, // Đã fix
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: const [FlSpot(0, 0), FlSpot(9, 50), FlSpot(24, 50)],
            isCurved: true,
            color: Colors.greenAccent, // Đã fix
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}