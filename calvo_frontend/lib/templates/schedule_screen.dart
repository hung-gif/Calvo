import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ReceivePort _port = ReceivePort();
  List<Map<String, dynamic>> _tasks = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAndMergeTasks();
    _setupListening();
  }

  Future<void> _loadAndMergeTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final String? savedUserTasks = prefs.getString('saved_tasks');
    List<Map<String, dynamic>> currentTasks = [];

    if (savedUserTasks != null) {
      final List<dynamic> decoded = jsonDecode(savedUserTasks);
      currentTasks = decoded.map((item) {
        final map = Map<String, dynamic>.from(item);
        map['start_time'] = DateTime.tryParse(map['start_time'] ?? '') ?? DateTime.now();
        map['color'] = Color(map['color_value'] ?? Colors.blue.value);
        return map;
      }).toList();
    }

    final List<String> inboxList = prefs.getStringList('schedule_data_list') ?? [];

    if (inboxList.isNotEmpty) {
      for (String item in inboxList) {
        try {
          final root = jsonDecode(item) as Map<String, dynamic>;
          final schedule = root['schedule_data'] as Map<String, dynamic>?;

          if (schedule == null) continue;

          final eventId = schedule['event_id']?.toString();
          final title = (schedule['event_title'] ?? 'New Event').toString();
          final startStr = schedule['start_time']?.toString();


          final startTime =
              DateTime.tryParse((startStr ?? '').replaceFirst(' ', 'T')) ??
              DateTime.now();

          final isExist = eventId != null &&
          currentTasks.any((t) => t['id']?.toString() == eventId);

          if (!isExist) {
            currentTasks.add({
              'id': eventId ?? DateTime.now().millisecondsSinceEpoch.toString(),
              'title': title,
              'start_time': startTime,
              'is_done': false,
              'color': Colors.orange,
              'color_value': Colors.orange.value,
            });
          }
        } catch (_) {}
      }

      await prefs.remove('schedule_data_list');
      
      final updatedJson = jsonEncode(currentTasks.map((t) {
        final copy = Map<String, dynamic>.from(t);
        copy['start_time'] = (copy['start_time'] as DateTime).toIso8601String();
        copy.remove('color');
        return copy;
      }).toList());
      
      await prefs.setString('saved_tasks', updatedJson);
    }

    if (mounted) {
      setState(() {
        _tasks = currentTasks;
        _tasks.sort((a, b) => a['start_time'].compareTo(b['start_time']));
      });
    }
  }

  void _setupListening() {
    IsolateNameServer.removePortNameMapping('schedule');
    IsolateNameServer.registerPortWithName(_port.sendPort, 'schedule');

    _port.listen((dynamic message) {
      if (message is Map<String, dynamic>) {
        _handleNewSchedule(message);
      }
    });
  }

  void _handleNewSchedule(Map<String, dynamic> json) {
  final schedule = json['schedule_data'] as Map<String, dynamic>?;

  if (schedule == null) return;

  final eventId = schedule['event_id']?.toString();
  final title = (schedule['event_title'] ?? 'New Event').toString();
  final startStr = schedule['start_time']?.toString(); // "2026-02-08 21:00"

  final startTime =
      DateTime.tryParse((startStr ?? '').replaceFirst(' ', 'T')) ??
      DateTime.now();

  final isExist = eventId != null && _tasks.any((t) => t['id']?.toString() == eventId);
  if (isExist) return;

  _autoPurge();

  final newTask = {
    'id': eventId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    'title': title,
    'start_time': startTime,
    'is_done': false,
    'color': Colors.orange,
    'color_value': Colors.orange.value,
  };

  if (mounted) {
    setState(() {
      _tasks.add(newTask);
      _tasks.sort((a, b) => (a['start_time'] as DateTime).compareTo(b['start_time'] as DateTime));
    });
    _saveScheduleStats();
  }
}

  Future<void> _saveScheduleStats() async {
    final prefs = await SharedPreferences.getInstance();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final List<Map<String, dynamic>> dataToSave = _tasks.map((task) {
      final copy = Map<String, dynamic>.from(task);
      copy['start_time'] = (copy['start_time'] as DateTime).toIso8601String();
      if (task['color'] is Color) {
         copy['color_value'] = (task['color'] as Color).value;
      }
      copy.remove('color');
      return copy;
    }).toList();

    await prefs.setString('saved_tasks', jsonEncode(dataToSave));

    final int pendingCount = _tasks.where((t) {
      return _isSameDay(t['start_time'], DateTime.now()) && t['is_done'] == false;
    }).length;

    await prefs.setInt('ov_tasks_pending', pendingCount);
    String summary = pendingCount > 0 
        ? "${userProvider.getText('ov_pending_msg')} $pendingCount ${userProvider.getText('stat_tasks2')}..." 
        : userProvider.getText('ov_done_msg');

    await prefs.setString('ov_schedule_summary', summary);
  }

  void _autoPurge() {
    final now = DateTime.now();
    setState(() {
      _tasks.removeWhere((task) {
        final startTime = task['start_time'] as DateTime;
        final diff = now.difference(startTime).inDays;
        
        if (task['is_done'] == true) return diff >= 1;
        return diff >= 2;
      });
    });
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('schedule');
    _port.close();
    super.dispose();
  }

  Future<void> _showFullCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Provider.of<UserProvider>(context, listen: false).primaryColor,
              surface: const Color(0xFF1A1A2E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = userProvider.isDarkMode;
    final primaryColor = userProvider.primaryColor;
    String t(String key) => userProvider.getText(key);
    final filteredTasks = _tasks.where((t) => _isSameDay(t['start_time'], _selectedDate)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildBackground(isDark, primaryColor),
          SafeArea(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showFullCalendar,
                  child: _buildWeekCalendar(isDark, primaryColor, userProvider.currentLanguage),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userProvider.getText('sect_schedule'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),),
                        const SizedBox(height: 16),                        
                        if (filteredTasks.isEmpty)
                          Center(child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(t('no_task'), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
                          ))
                        else
                          ...filteredTasks.map((task) => _buildTaskItem(task, isDark)).toList(),
                        
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, bool isDark) {
    final bool isDone = task['is_done'] ?? false;
    final Color color = task['color'] ?? Colors.blue;

    return Dismissible(
      key: Key(task['id'].toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) { setState(() => _tasks.remove(task)); _saveScheduleStats();},
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _glassDecoration(isDark).copyWith(
          border: Border(left: BorderSide(color: isDone ? Colors.green : color, width: 4)),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () { setState(() => task['is_done'] = !isDone);
              _saveScheduleStats();},
              child: Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isDone ? Colors.green : color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'],
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(task['start_time']),
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String title = "";
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20
          ),
          decoration: BoxDecoration(
            color: userProvider.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (v) => title = v,
                style: TextStyle(color: userProvider.isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: userProvider.getText('label_task_title'),
                  labelStyle: TextStyle(color: userProvider.isDarkMode ? Colors.white54 : Colors.black54)
                ),
              ),
              const SizedBox(height: 15),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.access_time, color: userProvider.primaryColor),
                title: 
                Text("${userProvider.getText('label_time')}: ${selectedTime.format(context)}",
                style: TextStyle(color: userProvider.isDarkMode ? Colors.white : Colors.black,),
                ),
                trailing: TextButton(
                  onPressed: () async {
                  final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                  builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                  child: child!,
                  );
                },
              );
                    if (picked != null) {
                      setModalState(() => selectedTime = picked);
                    }
                  },
                  child: Text(userProvider.getText('btn_pick_time'), style: TextStyle(color: userProvider.primaryColor)),
                ),
              ),
              
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: userProvider.primaryColor),
                  onPressed: () {
                    if (title.isNotEmpty) {
                      final finalDateTime = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      setState(() {
                        _tasks.add({
                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                          'title': title,
                          'start_time': finalDateTime,
                          'is_done': false,
                          'color': userProvider.primaryColor,
                          'color_value': userProvider.primaryColor.value,
                        });
                        _tasks.sort((a, b) => a['start_time'].compareTo(b['start_time']));
                      });
                      _saveScheduleStats(); 
                      Navigator.pop(context);
                    }
                  },
                  child: Text(userProvider.getText('btn_save_task'), style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [Colors.black, const Color(0xFF0F0C29), const Color(0xFF24243E)] 
            : [const Color(0xFFFDFBFB), const Color(0xFFEBEDEE)],
        ),
      ),
    );
  }

  BoxDecoration _glassDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4)),
    );
  }

  Widget _buildWeekCalendar(bool isDark, Color primaryColor, String langCode) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _glassDecoration(isDark),
      child: Column(
        children: [
          Text(
            DateFormat('MMMM yyyy', langCode == 'vi' ? 'vi_VN' : 'en_US').format(_selectedDate).toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isSelected = _isSameDay(date, _selectedDate);
              final hasTask = _tasks.any((t) => _isSameDay(t['start_time'], date));

              return InkWell(
                onTap: () => setState(() => _selectedDate = date),
                child: Column(
                  children: [
                    Text(langCode == 'vi' ? (index == 6 ? "CN" : "T${index + 2}") : DateFormat('E').format(date), 
                         style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.transparent,
                        shape: BoxShape.circle,
                        border: _isSameDay(date, now) ? Border.all(color: primaryColor) : null,
                      ),
                      child: Center(child: Text(date.day.toString(), style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black)))),
                    ),
                    if (hasTask) Container(margin: const EdgeInsets.only(top: 4), width: 4, height: 4, decoration: const BoxDecoration(color: Colors.tealAccent, shape: BoxShape.circle)),
                  ],
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}