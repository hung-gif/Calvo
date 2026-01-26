import 'dart:ui'; // Cần cho BackdropFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Lấy thông tin từ Provider
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = userProvider.isDarkMode;
    final primaryColor = userProvider.primaryColor;
    
    // Hàm dịch
    String t(String key) => userProvider.getText(key);

    // --- CẤU HÌNH MÀU NỀN & GLOW (ĐỒNG BỘ) ---
    final gradientColors = isDark 
        ? [const Color(0xFF000000), const Color(0xFF0F0C29), const Color(0xFF24243E)] // Dark Cyberpunk
        : [const Color(0xFFFDFBFB), const Color(0xFFEBEDEE)]; // Light Holographic
    
    final glowColor1 = isDark ? primaryColor.withOpacity(0.3) : primaryColor.withOpacity(0.15);
    final glowColor2 = isDark ? Colors.blueAccent.withOpacity(0.2) : Colors.purpleAccent.withOpacity(0.1);

    return Scaffold(
      backgroundColor: Colors.transparent, // Nền trong suốt để lộ Stack
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

          // --- 3. NỘI DUNG CHÍNH ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t('sect_notif'), // "Thông báo"
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87
                        )
                      ),
                      IconButton(
                        icon: Icon(Icons.done_all, color: primaryColor),
                        onPressed: () {},
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  Row(
                    children: [
                      _buildFilterChip(t, "Tất cả", true, isDark, primaryColor),
                      const SizedBox(width: 8),
                      _buildFilterChip(t, t('stat_important'), false, isDark, primaryColor), // Quan trọng
                      const SizedBox(width: 8),
                      _buildFilterChip(t, "Spam", false, isDark, primaryColor),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // List Items (Mock Data)
                  _buildDateHeader(t, "Hôm nay", isDark),
                  _buildNotifItem(
                    title: "Server Maintenance",
                    body: "Hệ thống bảo trì lúc 00:00. Vui lòng lưu dữ liệu.",
                    time: "10:00",
                    isUnread: true,
                    type: 'system',
                    isDark: isDark,
                  ),
                  _buildNotifItem(
                    title: "Payment Received",
                    body: "Bạn nhận được +5.000.000đ từ Lương tháng 1.",
                    time: "09:30",
                    isUnread: true,
                    type: 'money',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),
                  _buildDateHeader(t, "Hôm qua", isDark),
                  _buildNotifItem(
                    title: "Task Deadline",
                    body: "Task 'Review PR #234' sắp hết hạn.",
                    time: "Yesterday",
                    isUnread: false,
                    type: 'task',
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 80), // Padding đáy
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET CON ---

  Widget _buildFilterChip(Function t, String label, bool isSelected, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        // Hiệu ứng bóng đổ nhẹ cho Chip nếu không được chọn
        boxShadow: !isSelected && !isDark 
            ? [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] 
            : [],
        borderRadius: BorderRadius.circular(20)
      ),
      child: Chip(
        label: Text(
          label, 
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)
          )
        ),
        // Nền chip: Nếu chọn -> Primary. Nếu không -> Kính mờ (Glass)
        backgroundColor: isSelected 
            ? primaryColor 
            : (isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.6)),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildDateHeader(Function t, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text, 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          color: isDark ? Colors.white54 : Colors.grey[600]
        )
      ),
    );
  }

  Widget _buildNotifItem({
    required String title,
    required String body,
    required String time,
    required bool isUnread,
    required String type,
    required bool isDark,
  }) {
    IconData icon;
    Color color;

    switch (type) {
      case 'money': icon = Icons.attach_money; color = Colors.green; break;
      case 'task': icon = Icons.check_circle_outline; color = Colors.blue; break;
      case 'system': default: icon = Icons.info_outline; color = Colors.orange; break;
    }

    // Style nền (Glassmorphism)
    final decoration = isDark 
        ? BoxDecoration(
            // Dark: Chưa đọc -> Màu highlight nhẹ. Đã đọc -> Trong suốt
            color: isUnread ? color.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: isUnread ? Border.all(color: color.withOpacity(0.3)) : Border.all(color: Colors.white.withOpacity(0.1)),
          )
        : BoxDecoration(
            // Light: Chưa đọc -> Màu pastel. Đã đọc -> Trắng kính mờ
            color: isUnread ? color.withOpacity(0.05) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isUnread ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            border: isUnread ? Border.all(color: color.withOpacity(0.3)) : Border.all(color: Colors.white.withOpacity(0.4)),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: decoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15), // Icon nền đậm hơn chút
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87
                      )
                    ),
                    Text(
                      time, 
                      style: TextStyle(
                        fontSize: 12, 
                        color: isDark ? Colors.white38 : Colors.grey
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body, 
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}