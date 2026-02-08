import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_provider.dart';
import 'app_header.dart';

import 'mobile_overview_screen.dart';
import 'finance_screen.dart';
import 'schedule_screen.dart';
import 'notification_screen.dart';
import 'onboarding_screen.dart';

import '../services/notification_service.dart';
import '../services/briefing_service.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({Key? key}) : super(key: key);

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _selectedIndex = 0;
  final GlobalKey<MobileOverviewScreenState> _overviewKey = GlobalKey();

  static bool _didInitOnce = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        NotificationService.safeInit();

        if (_didInitOnce) return;
        _didInitOnce = true;

        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool('brief_enabled') ?? true;
        final hour = prefs.getInt('brief_hour') ?? 22;
        final minute = prefs.getInt('brief_minute') ?? 0;

        if (enabled) {
          await BriefingService.scheduleNextBriefing(hour: hour, minute: minute);
        } else {
          await BriefingService.cancelBriefing();
        }
      } catch (e) {
        debugPrint('MainWrapper init error: $e');
      }
    });
  }

  void _onNavigate(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      _overviewKey.currentState?.refreshAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userProvider.isFirstTime) {
      return const OnboardingScreen();
    }

    final List<Widget> screens = [
      MobileOverviewScreen(key: _overviewKey, onNavigate: _onNavigate),
      const FinanceScreen(),
      const ScheduleScreen(),
      const NotificationScreen(),
    ];

    return Scaffold(
      appBar: const AppHeader(),
      backgroundColor: userProvider.isDarkMode ? const Color(0xFF0F0C29) : const Color(0xFFF5F5F7),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavigate,
        type: BottomNavigationBarType.fixed,
        backgroundColor: userProvider.isDarkMode ? const Color(0xFF101015) : Colors.white,
        selectedItemColor: userProvider.primaryColor,
        unselectedItemColor: userProvider.isDarkMode ? Colors.white38 : Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: userProvider.getText('nav_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: userProvider.getText('nav_finance'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            activeIcon: const Icon(Icons.calendar_today),
            label: userProvider.getText('nav_schedule'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_outlined),
            activeIcon: const Icon(Icons.notifications),
            label: userProvider.getText('nav_notif'),
          ),
        ],
      ),
    );
  }
}
