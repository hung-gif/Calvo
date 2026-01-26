import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Quan trọng: Để format ngày tiếng Việt
import 'package:provider/provider.dart';
import 'package:calvo/templates/user_provider.dart';
import 'settings_screen.dart'; 

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userConfig = userProvider.userConfig;
    final primaryColor = userProvider.primaryColor;
    final isDark = userProvider.isDarkMode;
    
    // Hàm dịch
    String t(String key) => userProvider.getText(key);

    // Xử lý ngày tháng
    final now = DateTime.now();
    final localeCode = userProvider.currentLanguage; // Đảm bảo trả về 'vi' hoặc 'en'

    // Sửa lỗi logic: Khởi tạo dữ liệu ngôn ngữ trước khi format
    initializeDateFormatting(localeCode);
    final dateStr = DateFormat('EEEE, dd/MM/yyyy', localeCode).format(now);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            // SỬA LỖI: Thiếu dấu đóng ngoặc và số 9 ở opacity
            color: isDark ? const Color(0xFF1E1E1E).withOpacity(0.9) : Colors.white.withOpacity(0.9),
            border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : primaryColor.withOpacity(0.2))),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            bottom: 10,
            left: 16,
            right: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    // SỬA LỖI: Thiếu tham số padding
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        // SỬA LỖI: Thiếu số 9 ở opacity
                        colors: [primaryColor.withOpacity(0.9), primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8), // SỬA LỖI: Thiếu giá trị width
                  Text(
                    "Calvo",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : primaryColor
                    ),
                  ),
                ],
              ),

              // User Info
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${t('hello')}, ${userConfig['name'] ?? 'User'}", // Thêm null safety
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.w600, 
                          color: isDark ? Colors.white : Colors.black87
                        ),
                      ),
                      Text(dateStr, style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _getInitials(userConfig['name']),
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.settings, color: isDark ? Colors.white70 : Colors.grey),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getInitials(String? name) { 
    if (name == null || name.isEmpty) return "U"; 
    return name[0].toUpperCase(); 
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(80);
}