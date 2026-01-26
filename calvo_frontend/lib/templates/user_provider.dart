// lib/templates/user_provider.dart
import 'package:flutter/material.dart';
import '../services/local_db_service.dart';

class UserProvider extends ChangeNotifier {
  // 1. Các biến lưu trữ
  String _name = "User";
  String _job = "";         // Thêm nghề nghiệp
  String _aiName = "Calvo AI"; // Thêm tên AI
  String _aiAvatar = "🤖";    // Thêm Avatar AI
  
  // Lưu cả String màu để dễ lưu vào DB (purple, blue...)
  String _themeString = "purple"; 
  Color _primaryColor = Colors.deepPurple;
  
  bool _isDarkMode = true;
  String _currentLanguage = "vi";

  // 2. Getters (Để UI lấy dữ liệu lẻ)
  String get name => _name;
  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;
  String get currentLanguage => _currentLanguage;

  // --- 3. GETTER QUAN TRỌNG ĐỂ SỬA LỖI CỦA BẠN ---
  // Hàm này đóng gói toàn bộ dữ liệu thành 1 cục Map
  Map<String, dynamic> get userConfig => {
    'name': _name,
    'occupation': _job,
    'aiName': _aiName,
    'aiAvatar': _aiAvatar,
    'theme': _themeString,     // Trả về chuỗi 'purple'
    'mode': _isDarkMode ? 'dark' : 'light',
    'language': _currentLanguage,
  };

  // 4. Hàm Load dữ liệu từ DB (Chạy lúc mở App)
  Future<void> loadUserData() async {
    print("📥 [UserProvider] Loading data from DB...");
    final userData = await LocalDatabaseService.getUserData();

    if (userData != null) {
      _name = userData['name'] ?? "User";
      _themeString = userData['theme'] ?? "purple";
      _primaryColor = _getColorFromString(_themeString);
      
      String modeString = userData['mode'] ?? "dark";
      _isDarkMode = (modeString == "dark");
      
      // Nếu sau này bạn lưu thêm job, aiName vào DB thì load ở đây luôn
      // _job = userData['occupation'] ?? ""; 

      notifyListeners();
    }
  }

  // 5. Hàm cập nhật dữ liệu (Chạy ở Onboarding hoặc Settings)
  Future<void> updateConfig(Map<String, dynamic> newConfig) async {
    if (newConfig.containsKey('name')) _name = newConfig['name'];
    if (newConfig.containsKey('occupation')) _job = newConfig['occupation'];
    if (newConfig.containsKey('aiName')) _aiName = newConfig['aiName'];
    if (newConfig.containsKey('aiAvatar')) _aiAvatar = newConfig['aiAvatar'];
    
    if (newConfig.containsKey('theme')) {
      _themeString = newConfig['theme'];
      _primaryColor = _getColorFromString(_themeString);
    }
    
    if (newConfig.containsKey('mode')) {
      _isDarkMode = (newConfig['mode'] == 'dark');
    }
    
    if (newConfig.containsKey('language')) {
      _currentLanguage = newConfig['language'];
    }

    notifyListeners();
  }

  // Hàm phụ trợ đổi màu
  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'blue': return Colors.blue;
      case 'pink': return Colors.pink;
      case 'green': return Colors.teal;
      case 'purple': 
      default: return Colors.deepPurple;
    }
  }

  // Hàm dịch ngôn ngữ đơn giản
  String getText(String key) {
    Map<String, String> vi = {
      'next': 'Tiếp', 'back': 'Quay lại', 'skip': 'Bỏ qua', 'start': 'Bắt đầu',
      'lang_title': 'Ngôn ngữ', 'lang_subtitle': 'Chọn ngôn ngữ hiển thị',
      'info_title': 'Hồ sơ', 'info_subtitle': 'Cho tôi biết về bạn',
      'label_name': 'Tên của bạn', 'label_job': 'Nghề nghiệp', 'label_dob': 'Ngày sinh',
      'validate_name': 'Vui lòng nhập tên!', 'validate_date': 'Ngày sinh không hợp lệ',
      'ai_title': 'Trợ lý AI', 'ai_subtitle': 'Tùy chỉnh bạn đồng hành',
      'ai_select_avatar': 'Chọn Avatar', 'ai_name_label': 'Đặt tên cho AI',
      'theme_title': 'Giao diện', 'theme_subtitle': 'Chọn phong cách của bạn',
      'sect_color': 'Màu chủ đạo', 'sect_mode': 'Chế độ nền',
      'mode_light': 'Sáng', 'mode_dark': 'Tối'
    };
    
    Map<String, String> en = {
      'next': 'Next', 'back': 'Back', 'skip': 'Skip', 'start': 'Start',
      'lang_title': 'Language', 'lang_subtitle': 'Select display language',
      'info_title': 'Profile', 'info_subtitle': 'Tell me about yourself',
      'label_name': 'Your Name', 'label_job': 'Occupation', 'label_dob': 'Date of Birth',
      'validate_name': 'Please enter your name!', 'validate_date': 'Invalid date format',
      'ai_title': 'AI Companion', 'ai_subtitle': 'Customize your assistant',
      'ai_select_avatar': 'Select Avatar', 'ai_name_label': 'Name your AI',
      'theme_title': 'Appearance', 'theme_subtitle': 'Choose your style',
      'sect_color': 'Primary Color', 'sect_mode': 'Background Mode',
      'mode_light': 'Light', 'mode_dark': 'Dark'
    };

    if (_currentLanguage == 'vi') return vi[key] ?? key;
    return en[key] ?? key;
  }
}