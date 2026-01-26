// lib/shared/models/notification_model.dart
class AppNotification {
  final String id;
  final String appName; // Tên app gửi (Zalo, Messenger...)
  final String title;
  final String body;
  final DateTime time;
  final String category; // 'Tài chính', 'Lịch trình', 'Spam'...
  bool isSpam;
  bool isImportant;

  AppNotification({
    required this.id,
    required this.appName,
    required this.title,
    required this.body,
    required this.time,
    required this.category,
    this.isSpam = false,
    this.isImportant = false,
  });
}