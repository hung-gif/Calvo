import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ReceivePort _port = ReceivePort();
  final List<Map<String, dynamic>> _notifications = [];
  String _currentFilter = "all"; // all | important | spam

  @override
  void initState() {
    super.initState();
    _loadSavedNotifications();
    _setupListening();
  }

  Future<void> _loadSavedNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  final List<String> rawData = prefs.getStringList('all_notifications_list') ?? [];

  if (mounted) {
    setState(() {
      _notifications.clear();
      final List<Map<String, dynamic>> loadedList = rawData
      .map((item) => jsonDecode(item) as Map<String, dynamic>)
      .toList();

      _notifications.addAll(loadedList);
      _notifications.sort((a, b) {
         int pA = a['priority'] ?? 1;
         int pB = b['priority'] ?? 1;
         if (pA != pB) return pB.compareTo(pA); 
         final timeA = DateTime.tryParse(a['received_at'] ?? '') ?? DateTime.now();
         final timeB = DateTime.tryParse(b['received_at'] ?? '') ?? DateTime.now();
         return timeB.compareTo(timeA);
      });
    });
  }
}

  void _setupListening() {
    IsolateNameServer.removePortNameMapping('notification');
    IsolateNameServer.registerPortWithName(_port.sendPort, 'notification');

    _port.listen((dynamic message) {
      if (message is Map<String, dynamic>) {
        _handleNewNotification(message);
      }
    });
  }

  void _handleNewNotification(Map<String, dynamic> json) {
    final newTime = json['received_at'];
    final newTitle = json['title'] ?? json['source_app'] ?? 'System';
    final newBody = json['content'] ?? json['summary'] ?? '';
    final isExist = _notifications.any((n) => 
        n['received_at'] == newTime && 
        n['title'] == newTitle && 
        n['body'] == newBody
    );

    if (isExist) return;
    _autoPurge();

    final notif = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'classification': json['classification'] ?? 'IMPORTANT',
      'title': json['title'] ?? json['source_app'] ?? 'System',
      'body': json['content'] ?? json['summary'] ?? '',
      'received_at': json['received_at'] ?? DateTime.now().toIso8601String(),
      'priority': json['priority'] ?? 1,
      'is_spam': json['is_spam'] ?? false,
    };

    if (mounted) {
      setState(() {
        _notifications.add(notif);

        // Sort by priority DESC
        _notifications.sort((a, b) => b['priority'].compareTo(a['priority']));
      });
      _saveNotificationStats();
    }
  }

  Future<void> _saveNotificationStats() async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _notifications.map((n) {
    final m = Map<String, dynamic>.from(n);

    m['id'] = (m['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    m['classification'] = (m['classification'] ?? 'IMPORTANT').toString();
    m['title'] = (m['title'] ?? m['source_app'] ?? 'System').toString();
    m['body'] = (m['body'] ?? m['content'] ?? m['summary'] ?? '').toString();
    m['received_at'] = (m['received_at'] ?? DateTime.now().toIso8601String()).toString();

    final p = m['priority'];
    m['priority'] = (p is int) ? p : int.tryParse('$p') ?? 1;

    m['is_spam'] = m['is_spam'] == true;

    return m;
  }).toList();

  final raw = normalized.map((e) => jsonEncode(e)).toList();
  await prefs.setStringList('all_notifications_list', raw);
  await prefs.remove('saved_notifications');

  final importantCount = normalized.where((n) => n['priority'] == 5).length;
  final spamCount = normalized.where((n) => n['is_spam'] == true).length;

  await prefs.setInt('ov_notif_important', importantCount);
  await prefs.setInt('ov_notif_spam', spamCount);

  final summary = importantCount > 0
      ? "Có $importantCount thông báo quan trọng cần xử lý."
      : "Không có thông báo mới.";
  await prefs.setString('ov_notif_summary', summary);
}


  void _autoPurge() {
    final now = DateTime.now();
    setState(() {
      _notifications.removeWhere((n) {
        final receivedDate = DateTime.tryParse(n['received_at']) ?? now;
        final difference = now.difference(receivedDate).inDays;

        if (n['is_spam'] == true) {
          return difference >= 1;
        } else {
          return difference >= 3;
        }
      });
    });
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return "Now";
    try {
      final time = DateTime.parse(ts);
      return DateFormat('HH:mm').format(time);
    } catch (_) {
      return "Now";
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_currentFilter == "spam") {
      return _notifications.where((n) => n['is_spam'] == true).toList();
    }
    if (_currentFilter == "important") {
      return _notifications.where((n) => n['priority'] == 5).toList();
    }
    return _notifications.where((n) => n['is_spam'] == false).toList();
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('notification');
    _port.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = userProvider.isDarkMode;
    final primaryColor = userProvider.primaryColor;

    final gradientColors = isDark
        ? [
            const Color(0xFF000000),
            primaryColor.withOpacity(0.2),
            const Color(0xFF24243E),
          ]
        : [
            const Color(0xFFFDFBFB),
            primaryColor.withOpacity(0.1),
          ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),

          // ✅ FIX: Remove SingleChildScrollView. Use a bounded Column with Expanded list.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userProvider.getText('notif_title'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_sweep, color: primaryColor),
                        onPressed: () {
                          setState(() => _notifications.clear());
                          _saveNotificationStats();
                        },
                      )
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(userProvider.getText('filter_all'), "all"),
                        const SizedBox(width: 8),
                        _buildFilterChip(userProvider.getText('filter_important'), "important"),
                        const SizedBox(width: 8),
                        _buildFilterChip("Spam", "spam"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // List
                  Expanded(
                    child: _filteredNotifications.isEmpty
                        ? Center(
                            child: Text(
                              userProvider.getText('no_notif'),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero, // keep your spacing clean
                            itemCount: _filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final notif = _filteredNotifications[index];
                              return Dismissible(
                                key: Key((notif['id'] ?? index).toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (direction) {
                                  setState(() {
                                    _notifications.removeWhere(
                                      (element) => element['id'] == notif['id'],
                                    );
                                  });
                                  _saveNotificationStats();
                                },
                                child: _buildNotifItem(notif, isDark),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = userProvider.isDarkMode;
    final primaryColor = userProvider.primaryColor;
    final isSelected = _currentFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryColor,
      onSelected: (_) {
        setState(() => _currentFilter = value);
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black),
      ),
    );
  }

  Widget _buildNotifItem(Map<String, dynamic> notif, bool isDark) {
    IconData icon;
    Color color;

    switch (notif['classification']) {
      case 'FINANCE':
        icon = Icons.account_balance_wallet;
        color = Colors.greenAccent;
        break;
      case 'SCHEDULE':
        icon = Icons.event_note;
        color = Colors.blueAccent;
        break;
      case 'IMPORTANT':
        icon = Icons.priority_high;
        color = Colors.orangeAccent;
        break;
      default:
        icon = Icons.notifications_none;
        color = Colors.grey;
    }

    if (notif['priority'] == 5) color = Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        (notif['title'] ?? 'System').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(notif['received_at']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  (notif['body'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
