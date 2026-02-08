import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  // ====== SharedPrefs keys ======
  static const String kIsFirstTime = 'is_first_time';
  static const String kName = 'name';
  static const String kOccupation = 'occupation';
  static const String kBirthDate = 'birth_date';
  static const String kAiName = 'ai_name';
  static const String kAiAvatar = 'ai_avatar';
  static const String kTheme = 'theme';
  static const String kMode = 'mode';
  static const String kLanguage = 'language';

  // ====== State ======
  String _name = "User";
  String _job = "";
  String _aiName = "Calvo AI";
  String _aiAvatar = "🤖";

  String _themeString = "purple";
  Color _primaryColor = Colors.deepPurple;

  bool _isDarkMode = true;
  String _currentLanguage = "vi";

  DateTime? _birthDate;

  bool _isLoading = true;
  bool _isFirstTime = true;

  // ====== Getters ======
  String get name => _name;
  String get job => _job;
  String get aiName => _aiName;
  String get aiAvatar => _aiAvatar;

  String get themeString => _themeString;
  Color get primaryColor => _primaryColor;

  bool get isDarkMode => _isDarkMode;
  String get currentLanguage => _currentLanguage;

  DateTime? get birthDate => _birthDate;

  bool get isLoading => _isLoading;
  bool get isFirstTime => _isFirstTime;

  Map<String, dynamic> get userConfig => {
        'name': _name,
        'occupation': _job,
        'birthDate': _birthDate?.toIso8601String(),
        'aiName': _aiName,
        'aiAvatar': _aiAvatar,
        'theme': _themeString,
        'mode': _isDarkMode ? 'dark' : 'light',
        'language': _currentLanguage,
      };

  // ====== Load at app start ======
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    _isFirstTime = prefs.getBool(kIsFirstTime) ?? true;

    _name = prefs.getString(kName) ?? "User";
    _job = prefs.getString(kOccupation) ?? "";

    final birthStr = prefs.getString(kBirthDate);
    _birthDate = (birthStr == null || birthStr.isEmpty)
        ? null
        : DateTime.tryParse(birthStr);

    _aiName = prefs.getString(kAiName) ?? "Calvo AI";
    _aiAvatar = prefs.getString(kAiAvatar) ?? "🤖";

    _themeString = prefs.getString(kTheme) ?? "purple";
    _primaryColor = _getColorFromString(_themeString);

    final modeString = prefs.getString(kMode) ?? "dark";
    _isDarkMode = (modeString == "dark");

    _currentLanguage = prefs.getString(kLanguage) ?? "vi";

    _isLoading = false;
    notifyListeners();
  }

  // ====== Update config (used by onboarding + settings) ======
  Future<void> updateConfig(Map<String, dynamic> newConfig) async {
    final prefs = await SharedPreferences.getInstance();

    if (newConfig.containsKey('name')) {
      _name = (newConfig['name'] ?? "").toString();
      await prefs.setString(kName, _name);
    }

    if (newConfig.containsKey('occupation')) {
      _job = (newConfig['occupation'] ?? "").toString();
      await prefs.setString(kOccupation, _job);
    }

    if (newConfig.containsKey('birthDate')) {
      final v = newConfig['birthDate'];
      if (v == null || v.toString().isEmpty) {
        _birthDate = null;
        await prefs.remove(kBirthDate);
      } else {
        // v expected: ISO string
        _birthDate = DateTime.tryParse(v.toString());
        await prefs.setString(kBirthDate, v.toString());
      }
    }

    if (newConfig.containsKey('aiName')) {
      _aiName = (newConfig['aiName'] ?? "Calvo AI").toString();
      await prefs.setString(kAiName, _aiName);
    }

    if (newConfig.containsKey('aiAvatar')) {
      _aiAvatar = (newConfig['aiAvatar'] ?? "🤖").toString();
      await prefs.setString(kAiAvatar, _aiAvatar);
    }

    if (newConfig.containsKey('theme')) {
      _themeString = (newConfig['theme'] ?? "purple").toString();
      _primaryColor = _getColorFromString(_themeString);
      await prefs.setString(kTheme, _themeString);
    }

    if (newConfig.containsKey('mode')) {
      final mode = (newConfig['mode'] ?? "dark").toString();
      _isDarkMode = (mode == 'dark');
      await prefs.setString(kMode, mode);
    }

    if (newConfig.containsKey('language')) {
      _currentLanguage = (newConfig['language'] ?? "vi").toString();
      await prefs.setString(kLanguage, _currentLanguage);
    }

    notifyListeners();
  }

  // ====== Complete onboarding (FIX: set flag + persist) ======
  Future<void> completeOnboarding(Map<String, dynamic> config) async {
    // save all config
    await updateConfig(config);

    // set first time flag (IMPORTANT)
    final prefs = await SharedPreferences.getInstance();
    _isFirstTime = false;
    await prefs.setBool(kIsFirstTime, false);

    notifyListeners();
  }

  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'pink':
        return Colors.pink;
      case 'green':
        return Colors.teal;
      case 'purple':
      default:
        return Colors.deepPurple;
    }
  }

  String getText(String key) {
    Map<String, String> vi = {
      'next': 'Tiếp',
      'back': 'Quay lại',
      'skip': 'Bỏ qua',
      'start': 'Bắt đầu',
      'lang_title': 'Ngôn ngữ',
      'lang_subtitle': 'Chọn ngôn ngữ hiển thị',
      'info_title': 'Hồ sơ',
      'info_subtitle': 'Cho tôi biết về bạn',
      'label_name': 'Tên của bạn',
      'label_job': 'Nghề nghiệp',
      'label_dob': 'Ngày sinh',
      'validate_name': 'Vui lòng nhập tên!',
      'validate_date': 'Ngày sinh không hợp lệ',
      'ai_title': 'Trợ lý AI',
      'ai_subtitle': 'Tùy chỉnh bạn đồng hành',
      'ai_select_avatar': 'Chọn Avatar',
      'ai_name_label': 'Đặt tên cho AI',
      'theme_title': 'Giao diện',
      'theme_subtitle': 'Chọn phong cách của bạn',
      'sect_color': 'Màu chủ đạo',
      'sect_mode': 'Chế độ nền',
      'mode_light': 'Sáng',
      'mode_dark': 'Tối',
      'notif_title': 'Thông báo',
      'filter_all': 'Tất cả',
      'filter_important': 'Quan trọng',
      'filter_spam': 'Tin rác',
      'no_notif': 'Không có thông báo nào',
      'total_spending': 'Tổng chi tiêu tuần',
      'lbl_month_in': 'Tiền vào',
      'lbl_month_out': 'Tiền ra',
      'days': 'T2,T3,T4,T5,T6,T7,CN',
      'label_balance': 'Số dư',
      'sect_schedule': 'Việc cần làm',
      'no_task': 'Không có việc cần làm',
      'label_time': 'Thời gian',
      'label_task_title': 'Tiêu đề',
      'btn_pick_time': 'Chọn thời gian',
      'btn_save_task': 'Lưu',
      'balance': 'Số dư',
      'sect_finance': 'Tài chính',
      'chip_important': 'Quan Trọng',
      'chip_spam': 'Spam',
      'stat_tasks': 'Việc cần làm',
      'stat_balance': 'Tài khoản ngân hàng',
      'stat_important': 'Quan Trọng',
      'sect_notif': 'Thông báo',
      'ov_notif_important_msg': 'Bạn có',
      'ov_notif_important_suffix': 'thông báo quan trọng',
      'ov_notif_stable_msg': 'Hệ thống hoạt động ổn định',
      'ov_pending_msg': 'Còn',
      'stat_tasks2': 'công việc',
      'ov_done_msg': 'Hôm nay bạn đã hoàn thành hết công việc!',
      'daily_briefing_title': 'Tóm tắt',
      'no_briefing_yet': 'Chưa có tóm tắt',
      'updated_just_now': 'Tóm tắt mới',
      'language': 'Ngôn ngữ',
      'sect_profile': 'Thông tin cá nhân',
      'sect_ai_custom': 'Cá nhân hóa AI',
      'set_appearance': 'Giao diện',
      'nav_home': 'Màn hình chính',
      'nav_finance': 'Tài chính',
      'nav_schedule': 'Lịch trình',
      'nav_notif': 'Thông báo',
      'change_time': 'Thay đổi',
      'time': 'Thời gian',
      'no_trans': 'Chưa có giao dịch nào',
      'recent_transactions': 'Giao dịch gần đây',
      'edit_balance': 'Cập nhật số dư',
      'savebal': 'Lưu',
      'btn_cancel': 'Hủy',
      'btn_save': 'Lưu',
      'logout': 'Đăng xuất',
    };

    Map<String, String> en = {
      'next': 'Next',
      'back': 'Back',
      'skip': 'Skip',
      'start': 'Start',
      'lang_title': 'Language',
      'lang_subtitle': 'Select display language',
      'info_title': 'Profile',
      'info_subtitle': 'Tell me about yourself',
      'label_name': 'Your Name',
      'label_job': 'Occupation',
      'label_dob': 'Date of Birth',
      'validate_name': 'Please enter your name!',
      'validate_date': 'Invalid date format',
      'ai_title': 'AI Companion',
      'ai_subtitle': 'Customize your assistant',
      'ai_select_avatar': 'Select Avatar',
      'ai_name_label': 'Name your AI',
      'theme_title': 'Appearance',
      'theme_subtitle': 'Choose your style',
      'sect_color': 'Primary Color',
      'sect_mode': 'Background Mode',
      'mode_light': 'Light',
      'mode_dark': 'Dark',
      'notif_title': 'Notifications',
      'filter_all': 'All',
      'filter_important': 'Important',
      'filter_spam': 'Spam',
      'no_notif': 'No notifications',
      'total_spending': 'Total spending',
      'lbl_month_in': 'Income',
      'lbl_month_out': 'Expenses',
      'days': 'Mon,Tue,Wed,Thu,Fri,Sat,Sun',
      'label_balance': 'Balance',
      'sect_schedule': 'Task',
      'no_task': 'No task founded',
      'label_time': 'Time',
      'label_task_title': 'Title',
      'btn_pick_time': 'Pick time',
      'btn_save_task': 'Save task',
      'balance': 'Balance',
      'sect_finance': 'Finance',
      'chip_important': 'Important',
      'chip_spam': 'Spam',
      'stat_tasks': 'Task',
      'stat_balance': 'Bank account',
      'stat_important': 'Important',
      'sect_notif': 'Notification',
      'ov_notif_important_msg': 'You have',
      'ov_notif_important_suffix': 'important notifications.',
      'ov_notif_stable_msg': 'System is running stable.',
      'ov_pending_msg': 'Pending',
      'stat_tasks2': 'taks',
      'ov_done_msg': 'All tasks completed for today!',
      'daily_briefing_title': 'Daily Summary',
      'no_briefing_yet': 'No summary yet',
      'updated_just_now': 'New summary',
      'language': 'Language',
      'sect_profile': 'Profile',
      'sect_ai_custom': 'AI Personalization',
      'set_appearance': 'Appearance',
      'nav_home': 'Home',
      'nav_finance': 'Finance',
      'nav_schedule': 'Schedule',
      'nav_notif': 'Notifications',
      'change_time': 'Change',
      'no_trans': 'No transactions yet',
      'recent_transactions': 'Recent Transactions',
      'edit_balance': 'Update Balance',
      'savebal': 'Save',
      'btn_cancel': 'Cancel',
      'btn_save': 'Save',
      'logout': 'Logout',
    };

    if (_currentLanguage == 'vi') return vi[key] ?? key;
    return en[key] ?? key;
  }
}
