import 'dart:ui'; // Cần cho BackdropFilter
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = userProvider.isDarkMode;
    final primaryColor = userProvider.primaryColor;
    String t(String key) => userProvider.getText(key);

    // --- CẤU HÌNH MÀU NỀN & GLOW (ĐỒNG BỘ VỚI OVERVIEW) ---
    final gradientColors = isDark 
        ? [const Color(0xFF000000), const Color(0xFF0F0C29), const Color(0xFF24243E)] // Dark Cyberpunk
        : [const Color(0xFFFDFBFB), const Color(0xFFEBEDEE)]; // Light Holographic
    
    final glowColor1 = isDark ? primaryColor.withOpacity(0.3) : primaryColor.withOpacity(0.15);
    final glowColor2 = isDark ? Colors.tealAccent.withOpacity(0.15) : Colors.blue.withOpacity(0.1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // --- 1. BACKGROUND GRADIENT (LUÔN HIỆN) ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),
          
          // --- 2. ĐỐM SÁNG HUYỀN ẢO (LUÔN HIỆN) ---
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: glowColor1),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
            ),
          ),
          Positioned(
            bottom: 100, left: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: glowColor2),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
            ),
          ),

          // --- 3. NỘI DUNG CHÍNH ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lịch tuần
                  _buildWeekCalendar(isDark, primaryColor, userProvider.currentLanguage),
                  
                  const SizedBox(height: 24),
                  
                  // Tiêu đề
                  Text(
                    t('sect_schedule'), 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Danh sách công việc
                  _buildTaskItem(
                    title: "Review code PR #234",
                    time: "09:00 - 10:00",
                    color: Colors.green,
                    isDone: true,
                    isDark: isDark,
                  ),
                  _buildTaskItem(
                    title: "Viết báo cáo tuần",
                    time: "10:30 - 11:30",
                    color: Colors.green,
                    isDone: true,
                    isDark: isDark,
                  ),
                  _buildTaskItem(
                    title: "Họp team Sprint Planning",
                    time: "14:00 - 15:30",
                    color: Colors.blue,
                    isDone: false,
                    isDark: isDark,
                  ),
                  _buildTaskItem(
                    title: "Học Flutter (Calvo App)",
                    time: "20:00 - 22:00",
                    color: Colors.purple,
                    isDone: false,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 80), // Padding đáy
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        elevation: isDark ? 10 : 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: isDark ? BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 15)]
          ) : null,
          child: const Center(child: Icon(Icons.add, color: Colors.white)),
        ),
      ),
    );
  }

  // --- STYLE HELPER: HIỆU ỨNG KÍNH (CẢ 2 CHẾ ĐỘ) ---
  BoxDecoration _glassDecoration(bool isDark) {
    return BoxDecoration(
      // Light: Trắng đục (0.6). Dark: Trong suốt (0.05)
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
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

  Widget _buildWeekCalendar(bool isDark, Color primaryColor, String langCode) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final locale = langCode == 'vi' ? 'vi_VN' : 'en_US';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _glassDecoration(isDark),
      child: Column(
        children: [
          // Header Tháng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.chevron_left, color: isDark ? Colors.white70 : Colors.black54),
                Text(
                  DateFormat('MMMM yyyy', locale).format(now).toUpperCase(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                Icon(Icons.chevron_right, color: isDark ? Colors.white70 : Colors.black54),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Row Ngày
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isToday = _isSameDay(date, now);
              final isSelected = _isSameDay(date, _selectedDate);

              // Logic hiển thị thứ
              String dayName;
              if (langCode == 'vi') {
                 dayName = index == 6 ? "CN" : "T${index + 2}";
              } else {
                 dayName = DateFormat('E', 'en_US').format(date); // Mon, Tue...
              }

              return InkWell(
                onTap: () => setState(() => _selectedDate = date),
                child: Column(
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36, height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? primaryColor 
                            : (isToday ? primaryColor.withOpacity(0.2) : Colors.transparent),
                        shape: BoxShape.circle,
                        border: isToday && !isSelected ? Border.all(color: primaryColor) : null,
                        boxShadow: isSelected && isDark 
                            ? [BoxShadow(color: primaryColor.withOpacity(0.6), blurRadius: 10)] 
                            : [],
                      ),
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({required String title, required String time, required Color color, required bool isDone, required bool isDark}) {
    // Style cho item công việc (Glassmorphism phù hợp 2 chế độ)
    final decoration = isDark 
        ? BoxDecoration(
            color: isDone ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: isDone ? Colors.green : color, width: 4)),
          )
        : BoxDecoration(
            color: isDone ? Colors.green.withOpacity(0.05) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: isDone ? Colors.green : color, width: 4)),
            boxShadow: isDone ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: decoration,
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.green : color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: isDark ? Colors.white54 : Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      time, 
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 13)
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}