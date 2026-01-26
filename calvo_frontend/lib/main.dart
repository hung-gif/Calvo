// lib/main.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

// Import các file con của bạn
import 'templates/user_provider.dart';
import 'templates/onboarding_screen.dart';
import 'templates/main_wrapper_screen.dart';
import 'services/notification_service.dart';
import 'services/local_db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Cấu hình định dạng ngày tháng tiếng Việt
  await initializeDateFormatting('vi_VN', null);
  
  // 2. Khóa màn hình dọc (không cho xoay ngang)
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 3. Khởi tạo Service lắng nghe thông báo (Chạy ngầm)
  await NotificationService.init();

  // 4. QUAN TRỌNG: Kiểm tra xem trong Database đã có dữ liệu User chưa?
  // (Thay thế cho cách dùng SharedPreferences cũ)
  bool hasUser = await LocalDatabaseService.hasUserData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final provider = UserProvider();
          // 5. Nếu đã có User trong DB, nạp dữ liệu lên RAM ngay lập tức
          if (hasUser) {
            // Đảm bảo bạn đã viết hàm loadUserData() hoặc loadFromDb() trong UserProvider
            provider.loadUserData(); 
          }
          return provider;
        }),
      ],
      child: MyApp(hasUser: hasUser),
    ),
  );
}

// Chuyển thành StatefulWidget để xử lý xin quyền (Permission) lúc khởi động
class MyApp extends StatefulWidget {
  final bool hasUser;
  const MyApp({super.key, required this.hasUser});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
  @override
  void initState() {
    super.initState();
    // 6. Tự động kiểm tra và xin quyền truy cập thông báo ngay khi mở App
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    bool isRunning = (await NotificationsListener.isRunning) ?? false;
    print("🔔 Notification Service Running: $isRunning");
    
    if (!isRunning) {
      print("🔔 Requesting permission...");
      // Dòng này sẽ mở Cài đặt của Android nếu chưa cấp quyền
      await NotificationsListener.startService(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dùng Consumer để lắng nghe thay đổi màu sắc/chế độ sáng tối
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        
        final primaryColor = userProvider.primaryColor;
        final isDark = userProvider.isDarkMode;

        return MaterialApp(
          title: 'Calvo AI',
          debugShowCheckedModeBanner: false,
          
          // --- CẤU HÌNH THEME ĐỘNG ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: isDark ? Brightness.dark : Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
            scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
            appBarTheme: AppBarTheme(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black,
              elevation: 0,
            ),
          ),
          // ---------------------------

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('vi', 'VN'),
            Locale('en', 'US'),
          ],
          
          // 7. LOGIC ĐIỀU HƯỚNG
          // Nếu có User (hasUser == true) -> Vào MainWrapperScreen
          // Nếu chưa có (hasUser == false) -> Vào OnboardingScreen
          home: widget.hasUser ? const MainWrapperScreen() : const OnboardingScreen(),
        );
      },
    );
  }
}