enum TaskStatus { upcoming, completed }

class ScheduleTask {
  final String id;
  final String title;
  final DateTime startTime; // Dùng DateTime để dễ tính toán
  final DateTime endTime;
  TaskStatus status;
  final String category; // 'work', 'meeting', 'health', 'learning'
  final String icon;     // '💼', '💪'...

  ScheduleTask({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.category,
    required this.icon,
  });

  // Helper hiển thị giờ (VD: 09:00 - 10:00)
  String get timeRange {
    final start = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
    final end = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
    return "$start - $end";
  }
}

// Model cho lịch cố định hàng tuần (Weekly Schedule)
class WeeklyScheduleItem {
  final String id;
  final List<String> days; // ['Thứ 2', 'Thứ 4']
  final String time;
  final String activity;
  final String frequency; // 'Thường xuyên'

  WeeklyScheduleItem({
    required this.id,
    required this.days,
    required this.time,
    required this.activity,
    required this.frequency,
  });
}