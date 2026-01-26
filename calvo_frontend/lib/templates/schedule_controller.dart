// lib/features/schedule/logic/schedule_controller.dart
import 'package:flutter/material.dart';
import '../shared/models/schedule_model.dart';

class ScheduleController extends ChangeNotifier {
  DateTime selectedDate = DateTime.now();

  // Mock Data giống MobileSchedule.tsx
  List<ScheduleTask> tasks = [
    ScheduleTask(
      id: '1',
      title: 'Review code PR #234',
      startTime: DateTime.now().copyWith(hour: 9, minute: 0),
      endTime: DateTime.now().copyWith(hour: 10, minute: 0),
      status: TaskStatus.completed,
      category: 'work',
      icon: '💼',
    ),
    ScheduleTask(
      id: '2',
      title: 'Viết báo cáo tuần',
      startTime: DateTime.now().copyWith(hour: 10, minute: 30),
      endTime: DateTime.now().copyWith(hour: 11, minute: 30),
      status: TaskStatus.completed,
      category: 'work',
      icon: '💼',
    ),
    ScheduleTask(
      id: '3',
      title: 'Họp team Sprint Planning',
      startTime: DateTime.now().copyWith(hour: 14, minute: 0),
      endTime: DateTime.now().copyWith(hour: 15, minute: 30),
      status: TaskStatus.upcoming,
      category: 'meeting',
      icon: '👥',
    ),
    ScheduleTask(
      id: '4',
      title: 'Gym buổi chiều',
      startTime: DateTime.now().copyWith(hour: 17, minute: 0),
      endTime: DateTime.now().copyWith(hour: 18, minute: 0),
      status: TaskStatus.upcoming,
      category: 'health',
      icon: '💪',
    ),
  ];

  List<WeeklyScheduleItem> weeklyHabits = [
    WeeklyScheduleItem(id: '1', days: ['Thứ 2', 'Thứ 4', 'Thứ 6'], time: '6:30 AM', activity: 'Tập thể dục', frequency: 'Thường xuyên'),
    WeeklyScheduleItem(id: '2', days: ['Thứ 3', 'Thứ 5'], time: '20:00', activity: 'Học tiếng Anh', frequency: 'Học tập'),
  ];

  // Tính toán tiến độ
  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.status == TaskStatus.completed).length;
  double get progress => totalTasks == 0 ? 0 : completedTasks / totalTasks;

  // Logic chọn ngày
  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDate = selected;
    // Sau này gọi API lấy task theo ngày ở đây
    notifyListeners();
  }

  // Toggle trạng thái hoàn thành
  void toggleTaskStatus(String id) {
    final index = tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = tasks[index];
      tasks[index] = ScheduleTask(
        id: task.id,
        title: task.title,
        startTime: task.startTime,
        endTime: task.endTime,
        status: task.status == TaskStatus.completed ? TaskStatus.upcoming : TaskStatus.completed,
        category: task.category,
        icon: task.icon,
      );
      notifyListeners();
    }
  }
}