import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần để format ngày tháng
import 'package:provider/provider.dart';
import 'user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 1. Danh sách 4 màu chủ đạo (Bỏ màu 'dark' vì đã tách chế độ riêng)
  final List<Map<String, dynamic>> _colorOptions = const [
    {'name': 'Tím', 'value': 'purple', 'color': Colors.deepPurple},
    {'name': 'Xanh', 'value': 'blue', 'color': Colors.blue},
    {'name': 'Hồng', 'value': 'pink', 'color': Colors.pink},
    {'name': 'Lá', 'value': 'green', 'color': Colors.teal},
  ];

  // 2. Danh sách Chế độ nền (Mới)
  final List<Map<String, dynamic>> _modeOptions = const [
    {'key': 'mode_light', 'value': 'light', 'icon': Icons.wb_sunny_rounded},
    {'key': 'mode_dark', 'value': 'dark', 'icon': Icons.nights_stay_rounded},
  ];

  // Danh sách Avatar AI
  final List<String> _avatars = ['🤖', '✨', '🌟', '💫', '🎯', '🚀', '💜', '🔮'];

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ Provider
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = userProvider.isDarkMode;
    final primaryColor = userProvider.primaryColor;
    final userConfig = userProvider.userConfig;
    
    // Hàm rút gọn lấy từ điển
    String t(String key) => userProvider.getText(key);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(t('settings')),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. MỤC NGÔN NGỮ ---
            _buildSectionHeader(Icons.language, t('language'), isDark, primaryColor),
            const SizedBox(height: 12),
            Container(
              decoration: _boxDecoration(isDark),
              child: Column(
                children: [
                  _buildRadioItem("Tiếng Việt", "vi", userProvider),
                  Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                  _buildRadioItem("English", "en", userProvider),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. THÔNG TIN CÁ NHÂN ---
            _buildSectionHeader(Icons.person, t('sect_profile'), isDark, primaryColor),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _boxDecoration(isDark),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      (userConfig['name'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userConfig['name'] ?? "No Name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        const SizedBox(height: 4),
                        Text(userConfig['occupation'] ?? "No Job", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600])),
                        Text(
                          _formatDate(userConfig['birthDate']),
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: primaryColor),
                    onPressed: () => _showEditProfileDialog(context, userProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 3. CÁ NHÂN HÓA AI ---
            _buildSectionHeader(Icons.smart_toy, t('sect_ai_custom'), isDark, primaryColor),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _boxDecoration(isDark),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Text(userConfig['aiAvatar'] ?? "🤖", style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userConfig['aiName'] ?? "Calvo AI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        Text("Trợ lý ảo của bạn", style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: primaryColor),
                    onPressed: () => _showEditAIDialog(context, userProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 4. GIAO DIỆN & MÀU SẮC (SỬA ĐỔI LỚN) ---
            _buildSectionHeader(Icons.palette, t('set_appearance'), isDark, primaryColor),
            const SizedBox(height: 12),
            
            // A. Chọn Màu Chủ Đạo (4 ô tròn)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(t('sect_color'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _colorOptions.map((option) {
                final isSelected = userConfig['theme'] == option['value'];
                return InkWell(
                  onTap: () => userProvider.updateConfig({'theme': option['value']}),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 75, height: 75,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected ? Border.all(color: option['color'], width: 3) : null,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 8)],
                    ),
                    child: Center(
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: option['color'], shape: BoxShape.circle),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // B. Chọn Chế độ nền (2 ô to: Light / Dark)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(t('sect_mode'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
            ),
            Row(
              children: _modeOptions.map((option) {
                final currentMode = userConfig['mode'] ?? 'dark';
                final isSelected = currentMode == option['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => userProvider.updateConfig({'mode': option['value']}),
                    child: Container(
                      margin: EdgeInsets.only(right: option['value'] == 'light' ? 12 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? primaryColor.withOpacity(0.15) 
                            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? Border.all(color: primaryColor, width: 2) : Border.all(color: Colors.transparent),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 8)],
                      ),
                      child: Column(
                        children: [
                          Icon(option['icon'], color: isSelected ? primaryColor : Colors.grey, size: 30),
                          const SizedBox(height: 8),
                          Text(t(option['key']), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            
            // --- 5. LOGOUT ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(t('logout'), style: const TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              ),
            ),
            const SizedBox(height: 20),
            
            Center(child: Text("Calvo v1.0.0 • Your hair-saving assistant", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  // --- CÁC WIDGET PHỤ TRỢ ---
  
  Widget _buildSectionHeader(IconData icon, String title, bool isDark, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }

  BoxDecoration _boxDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10)],
    );
  }

  Widget _buildRadioItem(String title, String code, UserProvider provider) {
    final isSelected = provider.currentLanguage == code;
    final isDark = provider.isDarkMode;
    return InkWell(
      onTap: () => provider.updateConfig({'language': code}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: provider.primaryColor),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "";
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) { return isoDate; }
  }

  // --- DIALOGS ---

  void _showEditProfileDialog(BuildContext context, UserProvider provider) {
    final t = provider.getText;
    final nameCtrl = TextEditingController(text: provider.userConfig['name']);
    final jobCtrl = TextEditingController(text: provider.userConfig['occupation']);
    
    DateTime? selectedDate;
    final dobRaw = provider.userConfig['birthDate'];
    if (dobRaw != null) {
      try { selectedDate = DateTime.parse(dobRaw); } catch(_) {}
    }
    final dobCtrl = TextEditingController(text: selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate) : "");

    showDialog(
      context: context,
      builder: (context) {
        final isDark = provider.isDarkMode;
        final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;
        
        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(t('sect_profile'), style: TextStyle(color: textColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(nameCtrl, t('lbl_name'), isDark),
                const SizedBox(height: 12),
                _buildDialogTextField(jobCtrl, t('lbl_job'), isDark),
                const SizedBox(height: 12),
                TextField(
                  controller: dobCtrl,
                  style: TextStyle(color: textColor),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: t('lbl_dob'),
                    labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey[700]),
                    suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: provider.primaryColor, onPrimary: Colors.white, onSurface: Colors.black)), child: child!),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                      dobCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(child: Text(t('btn_cancel'), style: const TextStyle(color: Colors.grey)), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: provider.primaryColor, foregroundColor: Colors.white),
              child: Text(t('btn_save')),
              onPressed: () {
                provider.updateConfig({
                  'name': nameCtrl.text,
                  'occupation': jobCtrl.text,
                  'birthDate': selectedDate?.toIso8601String(),
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditAIDialog(BuildContext context, UserProvider provider) {
    final t = provider.getText;
    final aiNameCtrl = TextEditingController(text: provider.userConfig['aiName']);
    String tempAvatar = provider.userConfig['aiAvatar'] ?? "🤖";

    showDialog(
      context: context,
      builder: (context) {
        final isDark = provider.isDarkMode;
        final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;

        return StatefulBuilder( 
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: bgColor,
              title: Text(t('sect_ai_custom'), style: TextStyle(color: textColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(aiNameCtrl, t('lbl_ai_name'), isDark),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _avatars.map((avt) => InkWell(
                        onTap: () => setState(() => tempAvatar = avt),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tempAvatar == avt ? provider.primaryColor.withOpacity(0.2) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: tempAvatar == avt ? provider.primaryColor : Colors.transparent, width: 2),
                          ),
                          child: Text(avt, style: const TextStyle(fontSize: 24)),
                        ),
                      )).toList(),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(child: Text(t('btn_cancel'), style: const TextStyle(color: Colors.grey)), onPressed: () => Navigator.pop(context)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: provider.primaryColor, foregroundColor: Colors.white),
                  child: Text(t('btn_save')),
                  onPressed: () {
                    provider.updateConfig({
                      'aiName': aiNameCtrl.text,
                      'aiAvatar': tempAvatar,
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField(TextEditingController ctrl, String label, bool isDark) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey)),
      ),
    );
  }
}