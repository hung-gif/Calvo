import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'app_header.dart';

// Import các màn hình con
import 'mobile_overview_screen.dart';
import 'finance_screen.dart';
import 'schedule_screen.dart';
import 'notification_screen.dart';
import 'ai_assistant_screen.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  _MainWrapperScreenState createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _selectedIndex = 0;

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = userProvider.isDarkMode;
    final primaryColor = userProvider.primaryColor;
    
    String t(String key) => userProvider.getText(key);

    // Danh sách màn hình
    final List<Widget> screens = [
      MobileOverviewScreen(onNavigate: _onNavigate),
      const FinanceScreen(),
      const ScheduleScreen(),
      const NotificationScreen(),
    ];

    return Scaffold(
      // App Header (Giữ nguyên hoặc bạn có thể làm nó trong suốt ở file AppHeader)
      appBar: const AppHeader(),

      // Màu nền Scaffold tổng: 
      // Để màu trong suốt hoặc màu nền cơ bản để tránh bị nháy trắng khi chuyển tab
      backgroundColor: isDark ? const Color(0xFF0F0C29) : const Color(0xFFF5F5F7),

      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AIAssistantScreen()));
        },
        backgroundColor: primaryColor,
        elevation: isDark ? 10 : 4, // Dark mode đổ bóng đậm hơn chút cho nổi
        shape: const CircleBorder(),
        // Thêm viền phát sáng nhẹ cho nút AI trong Dark mode
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isDark 
                ? [BoxShadow(color: primaryColor.withOpacity(0.6), blurRadius: 15, spreadRadius: 1)]
                : [],
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavigate,
        type: BottomNavigationBarType.fixed,
        
        // --- CHỈNH MÀU NỀN NAVIGATION BAR ---
        // Dark: Dùng màu tối sẫm (gần đen) để tiệp với chân gradient của các màn hình con
        // Light: Trắng sạch
        backgroundColor: isDark ? const Color(0xFF101015) : Colors.white,
        
        selectedItemColor: primaryColor,
        
        // Dark: Màu trắng mờ (dễ nhìn hơn xám). Light: Màu xám.
        unselectedItemColor: isDark ? Colors.white38 : Colors.grey,
        
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 0, // Bỏ bóng mặc định để trông phẳng và hiện đại hơn (Cyberpunk style)
        
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined), 
            activeIcon: const Icon(Icons.dashboard), 
            label: t('nav_home')
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined), 
            activeIcon: const Icon(Icons.account_balance_wallet), 
            label: t('nav_finance')
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined), 
            activeIcon: const Icon(Icons.calendar_today), 
            label: t('nav_schedule')
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_outlined), 
            activeIcon: const Icon(Icons.notifications), 
            label: t('nav_notif')
          ),
        ],
      ),
    );
  }
}