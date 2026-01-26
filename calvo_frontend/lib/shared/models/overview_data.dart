class OverviewData {
  final NotificationStats notifications;
  final FinanceStats finance;
  final ScheduleStats schedule;

  OverviewData({required this.notifications, required this.finance, required this.schedule});

  // Mock data sẵn (giống file React cũ) để test UI
  static OverviewData get mock => OverviewData(
    notifications: NotificationStats(total: 47, important: 8, spam: 23, summary: 'Có 8 thông báo quan trọng...'),
    finance: FinanceStats(balance: 12450000, todayIncome: 0, todayExpense: 350000, summary: 'Chi tiêu hôm nay: 350k...'),
    schedule: ScheduleStats(totalTasks: 5, completed: 2, upcoming: 3, summary: 'Còn 3 công việc trong ngày...'),
  );
}

class NotificationStats {
  final int total;
  final int important;
  final int spam;
  final String summary;
  NotificationStats({required this.total, required this.important, required this.spam, required this.summary});
}

class FinanceStats {
  final double balance;
  final double todayIncome;
  final double todayExpense;
  final String summary;
  FinanceStats({required this.balance, required this.todayIncome, required this.todayExpense, required this.summary});
}

class ScheduleStats {
  final int totalTasks;
  final int completed;
  final int upcoming;
  final String summary;
  ScheduleStats({required this.totalTasks, required this.completed, required this.upcoming, required this.summary});
}