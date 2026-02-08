import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'main_wrapper_screen.dart';

class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 8) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      var index = i + 1;
      if ((index == 2 || index == 4) && index != digitsOnly.length) {
        buffer.write('/');
      }
    }
    final formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _aiNameController = TextEditingController(text: "Calvo AI");

  String _aiAvatar = "🤖";
  DateTime? _selectedDate;

  String _selectedColor = "purple";
  String _selectedMode = "dark";

  final List<Map<String, dynamic>> _colorOptions = [
    {'value': 'purple', 'color': Colors.deepPurple},
    {'value': 'blue', 'color': Colors.blue},
    {'value': 'pink', 'color': Colors.pink},
    {'value': 'green', 'color': Colors.teal},
  ];

  final List<Map<String, dynamic>> _modeOptions = [
    {'value': 'light', 'key': 'mode_light', 'icon': Icons.wb_sunny_rounded},
    {'value': 'dark', 'key': 'mode_dark', 'icon': Icons.nights_stay_rounded},
  ];

  final List<String> _avatars = ['🤖', '✨', '🌟', '💫', '🎯', '🚀', '💜', '🔮'];

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final primaryColor = userProvider.primaryColor;
    final isDark = _selectedMode == 'dark';
    String t(String key) => userProvider.getText(key);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF000000), Color(0xFF0F0C29), Color(0xFF24243E)]
                    : const [Color(0xFFFFFFFF), Color(0xFFF6F7FB), Color(0xFFEDEFF6)],
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? primaryColor.withOpacity(0.35)
                    : primaryColor.withOpacity(0.18),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.blueAccent.withOpacity(0.20)
                    : Colors.blueAccent.withOpacity(0.10),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / 4,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: [
                      _buildPage0_Language(t, primaryColor),
                      _buildPage1_Info(t, primaryColor),
                      _buildPage2_AICustom(t, primaryColor),
                      _buildPage3_Theme(t, primaryColor),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          },
                          child: Text(t('back'),
                              style: const TextStyle(color: Colors.white54)),
                        )
                      else
                        const SizedBox(width: 60),
                      Row(
                        children: [
                          if (_currentPage > 1)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextButton(
                                onPressed: _handleSkip,
                                child: Text(t('skip'),
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(boxShadow: [
                              BoxShadow(
                                  color: primaryColor.withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4))
                            ]),
                            child: ElevatedButton(
                              onPressed: () => _handleNext(t),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: Text(
                                _currentPage == 3 ? t('start') : t('next'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.completeOnboarding({
      'name': _nameController.text,
      'occupation': _jobController.text,
      'birthDate': _selectedDate?.toIso8601String(),
      'aiName': _aiNameController.text,
      'aiAvatar': _aiAvatar,
      'theme': _selectedColor,
      'mode': _selectedMode,
    });

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
    );
  }

  void _handleSkip() {
    if (_currentPage < 3) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  void _handleNext(Function t) {
    if (_currentPage == 0) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
      return;
    }
    if (_currentPage == 1) {
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t('validate_name'),
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.withOpacity(0.8),
        ));
        return;
      }
      if (_dobController.text.isNotEmpty) {
        try {
          final tempDate =
              DateFormat('dd/MM/yyyy').parseStrict(_dobController.text);
          setState(() => _selectedDate = tempDate);
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(t('validate_date'))));
          return;
        }
      }
    }
    if (_currentPage < 3) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: Locale(userProvider.currentLanguage, ''),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: userProvider.primaryColor,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogTheme:
                DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  InputDecoration _futuristicInputDeco(
      String label, IconData icon, Color primary) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    );
  }

  Widget _buildPage0_Language(Function t, Color primary) {
    final userProvider = Provider.of<UserProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5)
                ],
                border: Border.all(color: primary.withOpacity(0.5))),
            child: const Icon(Icons.language,
                size: 50, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(t('lang_title'),
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Text(t('lang_subtitle'),
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 48),
          _buildLangOption("Tiếng Việt", "vi",
              userProvider.currentLanguage, primary,
              () => userProvider.updateConfig({'language': 'vi'})),
          const SizedBox(height: 16),
          _buildLangOption("English", "en",
              userProvider.currentLanguage, primary,
              () => userProvider.updateConfig({'language': 'en'})),
        ],
      ),
    );
  }

  Widget _buildLangOption(String label, String code, String current,
      Color primary, VoidCallback onTap) {
    final isSelected = current == code;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
            color: isSelected
                ? primary.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            border: Border.all(
                color: isSelected
                    ? primary
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Text("",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const Spacer(),
          if (isSelected)
            Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                    boxShadow: [
                      BoxShadow(color: primary, blurRadius: 10)
                    ]),
                child: const Icon(Icons.check,
                    color: Colors.white, size: 20))
        ]),
      ),
    );
  }

  Widget _buildPage1_Info(Function t, Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text("${t('info_title')}\n${t('info_subtitle')}",
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: Colors.white)),
          const SizedBox(height: 40),
          TextField(
              controller: _nameController,
              style:
                  const TextStyle(color: Colors.white, fontSize: 18),
              decoration: _futuristicInputDeco(
                  t('label_name'),
                  Icons.person_outline,
                  primary)),
          const SizedBox(height: 20),
          TextField(
              controller: _jobController,
              style:
                  const TextStyle(color: Colors.white, fontSize: 18),
              decoration: _futuristicInputDeco(
                  t('label_job'),
                  Icons.work_outline,
                  primary)),
          const SizedBox(height: 20),
          TextField(
              controller: _dobController,
              keyboardType: TextInputType.number,
              inputFormatters: [DateTextFormatter()],
              style:
                  const TextStyle(color: Colors.white, fontSize: 18),
              decoration: _futuristicInputDeco(
                      t('label_dob'),
                      Icons.cake_outlined,
                      primary)
                  .copyWith(
                      suffixIcon: IconButton(
                          icon: const Icon(
                              Icons.calendar_today,
                              color: Colors.white70),
                          onPressed: () => _selectDate(context)),
                      hintText: "dd/mm/yyyy",
                      hintStyle:
                          const TextStyle(color: Colors.white38))),
        ],
      ),
    );
  }

  Widget _buildPage2_AICustom(Function t, Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withOpacity(0.2),
                        border: Border.all(
                            color: primary.withOpacity(0.5),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  primary.withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 5)
                        ]),
                    alignment: Alignment.center,
                    child: Text(_aiAvatar,
                        style:
                            const TextStyle(fontSize: 50)))),
            const SizedBox(height: 32),
            Text("${t('ai_title')}\n${t('ai_subtitle')}",
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: Colors.white)),
            const SizedBox(height: 32),
            Text(t('ai_select_avatar'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70)),
            const SizedBox(height: 16),
            Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _avatars
                    .map((avt) => InkWell(
                        onTap: () =>
                            setState(() => _aiAvatar = avt),
                        borderRadius:
                            BorderRadius.circular(40),
                        child: Container(
                            padding:
                                const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: _aiAvatar == avt
                                    ? primary
                                        .withOpacity(0.3)
                                    : Colors.white
                                        .withOpacity(0.05),
                                border: Border.all(
                                    color:
                                        _aiAvatar == avt
                                            ? primary
                                            : Colors
                                                .transparent,
                                    width: 2),
                                shape: BoxShape.circle,
                                boxShadow: _aiAvatar ==
                                        avt
                                    ? [
                                        BoxShadow(
                                            color: primary
                                                .withOpacity(
                                                    0.5),
                                            blurRadius: 15)
                                      ]
                                    : []),
                            child: Text(avt,
                                style: const TextStyle(
                                    fontSize: 28)))))
                    .toList()),
            const SizedBox(height: 32),
            TextField(
                controller: _aiNameController,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18),
                decoration: _futuristicInputDeco(
                    t('ai_name_label'),
                    Icons.smart_toy_outlined,
                    primary)),
          ]),
    );
  }

  Widget _buildPage3_Theme(Function t, Color primary) {
    final isDark = _selectedMode == 'dark';
    final textColor =
        isDark ? Colors.white : Colors.black87;
    final subTextColor =
        isDark ? Colors.white70 : Colors.black54;
    final glassColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);
    final borderColor =
        isDark ? Colors.white10 : Colors.black12;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.palette_outlined,
              size: 48, color: textColor),
          const SizedBox(height: 24),
          Text("${t('theme_title')}\n${t('theme_subtitle')}",
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: textColor)),
          const SizedBox(height: 32),
          Text(t('sect_color'),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: subTextColor)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: _colorOptions.map((option) {
              final isSelected =
                  _selectedColor == option['value'];
              final Color optColor = option['color'];
              return InkWell(
                onTap: () {
                  setState(() =>
                      _selectedColor =
                          option['value']);
                  context
                      .read<UserProvider>()
                      .updateConfig({
                    'theme': option['value']
                  });
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      color: glassColor,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: optColor,
                              width: 2)
                          : Border.all(
                              color: borderColor),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: optColor
                                      .withOpacity(0.3),
                                  blurRadius: 15)
                            ]
                          : []),
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: optColor,
                          shape: BoxShape.circle),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white,
                              size: 18)
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(t('sect_mode'),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: subTextColor)),
          const SizedBox(height: 16),
          Row(
            children: _modeOptions.map((option) {
              final isSelected =
                  _selectedMode == option['value'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() =>
                        _selectedMode =
                            option['value']);
                    context
                        .read<UserProvider>()
                        .updateConfig({
                      'mode': option['value']
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                        right: option['value'] ==
                                'light'
                            ? 12
                            : 0),
                    padding:
                        const EdgeInsets.symmetric(
                            vertical: 20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary.withOpacity(
                              isDark ? 0.2 : 0.1)
                          : glassColor,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: primary,
                              width: 2)
                          : Border.all(
                              color: borderColor),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: primary
                                      .withOpacity(
                                          0.3),
                                  blurRadius: 10)
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(option['icon'],
                            color: isSelected
                                ? primary
                                : subTextColor,
                            size: 30),
                        const SizedBox(height: 8),
                        Text(t(option['key']),
                            style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                color: textColor)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
