import 'dart:ui'; 
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'dart:isolate';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int touchedIndex = -1;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
 
  double totalIncome = 0.0; //monthly
  double totalExpense = 0.0;
  List<double> weeklySpending = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];//week
  int currentWeekNumber = 0;//weektracker
  bool get isBudgetBroken => totalExpense > totalIncome * 0.8; 

  // ============================================================
  final ReceivePort _port = ReceivePort();
  @override
  void initState() {
    super.initState();
    _setupListening();
    _checkNewWeek();
  }

  void _checkNewWeek() {
    DateTime now = DateTime.now();
    int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    int thisWeek = (dayOfYear / 7).ceil();
    
    if (thisWeek != currentWeekNumber) {
      setState(() {
        // RESET: New week detected -> Clear all data
        weeklySpending = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        currentWeekNumber = thisWeek;
      });
    }
  }//weektracker

  void _setupListening() {
    IsolateNameServer.removePortNameMapping('update_finance_ui');

    IsolateNameServer.registerPortWithName(_port.sendPort, 'update_finance_ui');

    _port.listen((dynamic message) {
      if (message is Map<String, dynamic>) {
        _handleNewData(message);
      }
    });
  } //notification listener

  void _handleNewData(Map<String, dynamic> json) {
    print("💰 Finance data received: $json");

    String type = json['type_of_transaction'] ?? 'UNKNOWN';
    if (type == 'UNKNOWN') return;

    double amount = (json['amount'] as num).toDouble();

    if (mounted) {
      setState(() {
        if (type == 'DEPOSIT') {
          totalIncome += amount;
        } else if (type == 'WITHDRAW') {
          totalExpense += amount;
        }
      });
    }
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('update_finance_ui');
    _port.close();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = userProvider.isDarkMode;
    final primaryColor = userProvider.primaryColor;
    
    // Hàm lấy ngôn ngữ
    String t(String key) => userProvider.getText(key);

    // Cấu hình màu nền Gradient
    final gradientColors = isDark 
        ? [const Color(0xFF000000), const Color(0xFF0F0C29), const Color(0xFF24243E)]
        : [const Color(0xFFFDFBFB), const Color(0xFFEBEDEE)];
    
    // Cấu hình màu đốm sáng (Glow)
    final glowColor1 = isDark ? primaryColor.withOpacity(0.3) : primaryColor.withOpacity(0.15);
    final glowColor2 = isDark ? Colors.redAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.1);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          //GRADIENT
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),
          
          //Glow
          Positioned(
            top: -100, left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: glowColor1),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
            ),
          ),
          Positioned(
            bottom: -50, right: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: glowColor2),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
            ),
          ),

          // CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Chart
                  Container(
                    height: 380, 
                    padding: const EdgeInsets.all(24),
                    decoration: _glassDecoration(isDark),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t('Total spending'),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
                                ),
                                Text(
                                  "This week", 
                                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.grey)
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.bar_chart, color: primaryColor),
                            )
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        Expanded(
                          child: BarChart(
                            mainBarData(weeklySpending, isDark)
                          )
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Money in & out
                  Row(
                    children: [
                      _buildMonthlyStatCard(
                        title: t('lbl_month_in'),
                        amount: totalIncome,
                        color: Colors.green,
                        icon: Icons.arrow_upward,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _buildMonthlyStatCard(
                        title: t('lbl_month_out'),
                        amount: totalExpense,
                        color: Colors.red,
                        icon: Icons.arrow_downward,
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // CFO AGENT suggestion
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _glassDecoration(isDark).copyWith(
                      color: isBudgetBroken 
                          ? (isDark ? Colors.red.withOpacity(0.15) : Colors.red.withOpacity(0.05)) 
                          : (isDark ? primaryColor.withOpacity(0.15) : primaryColor.withOpacity(0.05)),
                      border: Border.all(
                        color: isBudgetBroken ? Colors.red.withOpacity(0.5) : primaryColor.withOpacity(0.3),
                        width: 1
                      )
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isBudgetBroken ? Icons.warning_amber_rounded : Icons.check_circle, 
                              color: isBudgetBroken ? Colors.red : primaryColor,
                              size: 28,
                            ), 
                            const SizedBox(width: 8),
                            Text(
                              isBudgetBroken ? t('ai_status_danger') : t('ai_status_safe'), 
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold, 
                                color: isBudgetBroken ? Colors.red : (isDark ? Colors.white : Colors.black87)
                              )
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // advice box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                              topLeft: Radius.circular(4), 
                            ),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.white54),
                          ),
                          child: Text(
                            isBudgetBroken ? t('ai_advice_danger') : t('ai_advice_safe'),
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87, 
                              height: 1.4,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  
                
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  BoxDecoration _glassDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4), 
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



  Widget _buildMonthlyStatCard({required String title, required double amount, required Color color, required IconData icon, required bool isDark}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: _glassDecoration(isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), 
              child: Icon(icon, color: color, size: 20)
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
            const SizedBox(height: 4),
            Text(currencyFormatter.format(amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }


  Widget _bottomTitles(double value, TitleMeta meta, bool isDark) {
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
    final color = isDark ? Colors.white54 : Colors.grey; 
    
    String text;
    switch (value.toInt()) {
      case 0: text = 'Tổng Chi'; break;
      default: text = '';
    }
    

    return SideTitleWidget(
      axisSide: meta.axisSide, 
      space: 4, 
      child: Text(text, style: style.copyWith(color: color)),
    );
  }


  BarChartData mainBarData(List<double> weeklyData, bool isDark) {
  // Calculate dynamic maxY based on the highest value in the list
  double maxVal = weeklyData.reduce((curr, next) => curr > next ? curr : next);
  double maxY = maxVal == 0 ? 1000000 : maxVal * 1.2;

  return BarChartData(
    maxY: maxY,
    minY: 0,
    gridData: FlGridData(show: false),
    borderData: FlBorderData(show: false),

    titlesData: FlTitlesData(
      show: true,
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => _bottomTitles(value, meta, isDark),
        ),
      ),
    ),

    barTouchData: BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipBgColor: Colors.red,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            NumberFormat.compact(locale: 'vi').format(rod.toY),
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          );
        },
      ),
    ),

    // Generate 7 bars (Mon-Sun) from the input list
    barGroups: List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weeklyData[index],
            color: Colors.red,
            width: 20, // Reduced width to fit 7 bars on screen
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
        ],
      );
    }),
  );
 }
}