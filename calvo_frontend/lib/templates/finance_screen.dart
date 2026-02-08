import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'dart:isolate';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final ReceivePort _port = ReceivePort();

  List<Map<String, dynamic>> _transactions = [];
  double totalIncome = 0;
  double totalExpense = 0;
  double currentBalance = 0;
  String currentCurrency = 'đ';
  List<double> weeklySpending = List.filled(7, 0.0);

  @override
  void initState() {
    super.initState();
    _loadUserBalance().then((_) => _loadFinanceData());
    _setupListening();
  }
  
  Future<void> _loadUserBalance() async {
  final prefs = await SharedPreferences.getInstance();
  currentBalance = prefs.getDouble('user_balance') ?? 0.0;
  currentCurrency = prefs.getString('user_currency') ?? 'đ';
}

  Future<void> _saveUserBalance() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('user_balance', currentBalance);
  await prefs.setString('user_currency', currentCurrency);
}


  Future<void> _loadFinanceData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> rawList = prefs.getStringList('finance_data_list') ?? [];

    if (mounted) {
      setState(() {
  _transactions = rawList.map((item) {
    final root = jsonDecode(item) as Map<String, dynamic>;
    final fin = root['finance_data'] as Map<String, dynamic>?;

    final tx = fin != null ? Map<String, dynamic>.from(fin) : Map<String, dynamic>.from(root);

    tx['received_at'] = (tx['received_at'] ?? root['received_at'] ?? '').toString();
    return tx;
  }).toList();

  _transactions.sort((a, b) {
    final dateA = DateTime.tryParse((a['received_at'] ?? '').toString());
    final dateB = DateTime.tryParse((b['received_at'] ?? '').toString());
    if (dateA == null || dateB == null) return 0;
    return dateB.compareTo(dateA);
  });

  _recalculateTotals();
});
    }
  }

  void _recalculateTotals() {
    double inc = 0;
    double exp = 0;
    List<double> week = List.filled(7, 0.0);
    DateTime now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    int currentYear = now.year;
    int currentMonth = now.month;

    for (var t in _transactions) {
      double amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      String type = t['type_of_transaction'] ?? 'UNKNOWN';
      final raw = (t['received_at'] ?? '').toString();
      final date = DateTime.tryParse(raw) ??
      DateTime.tryParse(raw.replaceFirst(' ', 'T')) ??
      DateTime.now();

      bool isThisMonth = date.month == currentMonth && date.year == currentYear;

      if (type == 'DEPOSIT') {
        if (isThisMonth) {
          inc += amount;
        }
      } else if (type == 'WITHDRAW') {
        if (isThisMonth) {
          exp += amount;
        }

        final day = DateTime(date.year, date.month, date.day);
        if (!day.isBefore(startOfWeek) && day.isBefore(startOfWeek.add(const Duration(days: 7)))) {
          final idx = day.weekday - 1; // 0..6
          week[idx] += amount;
          }

      }
    }

    totalIncome = inc;
    totalExpense = exp;
    weeklySpending = week;
  }

  void _setupListening() {
  IsolateNameServer.removePortNameMapping('finance');
  IsolateNameServer.registerPortWithName(_port.sendPort, 'finance');

  _port.listen((dynamic message) async {
    if (message is! Map<String, dynamic> || !mounted) return;

    final root = Map<String, dynamic>.from(message);
    final fin = root['finance_data'] as Map<String, dynamic>?;
    final tx = fin != null ? Map<String, dynamic>.from(fin) : root;

    tx['received_at'] = (tx['received_at'] ?? root['received_at'] ?? '').toString();

    final newTime = tx['received_at'];
    final isExist = _transactions.any((t) => (t['received_at'] ?? '').toString() == newTime);
    if (isExist) {
      print("⚠️ Transaction existed.");
      return;
    }

    final a = tx['amount'];
    final amount = (a is num) ? a.toDouble() : double.tryParse(a?.toString() ?? '') ?? 0.0;

    final type = (tx['type_of_transaction'] ?? '').toString();

    setState(() {
      _transactions.insert(0, tx);

      if (type == 'DEPOSIT') {
        currentBalance += amount;
      } else if (type == 'WITHDRAW') {
        currentBalance -= amount;
      }

      _recalculateTotals();
    });
    await _saveUserBalance();
  });
}



  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('finance');
    _port.close();
    super.dispose();
  }

  String _formatMoney(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)} $currentCurrency";
  }

  Widget _buildTransactionList(BuildContext context,bool isDark, Color primaryColor) {
    final userProvider = context.watch<UserProvider>();
    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            userProvider.getText('no_trans'),
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final item = _transactions[index];
        final type = item['type_of_transaction'] ?? 'UNKNOWN';
        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
        final title = item['title'] ?? 'Giao dịch';
        final content = item['content'] ?? '';
        final dateStr = item['received_at'] ?? '';
        final isDeposit = type == 'DEPOSIT';

        DateTime date = DateTime.tryParse(dateStr) ?? DateTime.now();
        String timeFormatted = DateFormat('HH:mm dd/MM').format(date);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: _glass(isDark, primaryColor).copyWith(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDeposit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isDeposit ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (content.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isDeposit ? '+' : '-'}${_formatMoney(amount)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDeposit ? Colors.green : Colors.red,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeFormatted,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = userProvider.isDarkMode;
    final primaryColor = userProvider.primaryColor;
    String t(String key) => userProvider.getText(key);

    final gradientColors = isDark
        ? [const Color(0xFF000000), primaryColor.withOpacity(0.15), const Color(0xFF1A1A2E)]
        : [const Color(0xFFFDFBFB), primaryColor.withOpacity(0.05)];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Balance
                        InkWell(
                          onTap: _showEditBalanceSheet,
                          borderRadius: BorderRadius.circular(20),
                          child: _balanceCard(t('label_balance'), currentBalance, primaryColor, isDark),
                        ),
                        const SizedBox(height: 16),

                        // Chart
                        Container(
                          height: 300,
                          padding: const EdgeInsets.all(24),
                          decoration: _glass(isDark, primaryColor),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    t('total_spending'),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black),
                                  ),
                                  Icon(Icons.bar_chart, color: primaryColor)
                                ],
                              ),
                              const SizedBox(height: 24),
                              Expanded(
                                child: BarChart(mainBarData(weeklySpending, isDark)),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Stats (Income / Expense)
                        Row(
                          children: [
                            _statCard(t('lbl_month_in'), totalIncome, Colors.green, Icons.arrow_upward, isDark, primaryColor),
                            const SizedBox(width: 12),
                            _statCard(t('lbl_month_out'), totalExpense, Colors.red, Icons.arrow_downward, isDark, primaryColor),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Recent Transactions Title
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            t('recent_transactions'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Transaction List
                        _buildTransactionList(context,isDark, primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ================= UI helpers =================

  Widget _balanceCard(String title, double amount, Color primaryColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _glass(isDark, primaryColor).copyWith(
        gradient: LinearGradient(colors: [primaryColor.withOpacity(0.2), primaryColor.withOpacity(0.05)]),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
          const SizedBox(height: 8),
          Text(_formatMoney(amount),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }

  Future<void> _showEditBalanceSheet() async {
  final prefs = await SharedPreferences.getInstance();

  final controller = TextEditingController(
    text: currentBalance == 0 ? '' : currentBalance.toStringAsFixed(0),
  );

  final currencies = <String>['đ', '\$', '€', '¥', '₩'];

  String selectedCurrency = currentCurrency.isNotEmpty ? currentCurrency : 'đ';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final isDark = userProvider.isDarkMode;

        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userProvider.getText('edit_balance'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Input balance
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Balance",
                  labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 12),

              // Currency picker
              Row(
                children: [
                  Text(
                    "Currency:",
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: currencies.contains(selectedCurrency) ? selectedCurrency : currencies.first,
                    dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    items: currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setModalState(() => selectedCurrency = v);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final raw = controller.text.trim().replaceAll(',', '');
                    final val = double.tryParse(raw) ?? 0.0;

                    setState(() {
                      currentBalance = val;
                      currentCurrency = selectedCurrency;
                    });

                    await _saveUserBalance();

                    Navigator.pop(context);
                  },
                  child: Text(userProvider.getText('savebal')),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}


  BoxDecoration _glass(bool isDark, Color primaryColor) {
    return BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(isDark ? 0.2 : 0.5),
        ));
  }

  Widget _statCard(String title, double amount, Color color, IconData icon, bool isDark, Color primaryColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _glass(isDark, primaryColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            Text(_formatMoney(amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // ================= CHART =================

  BarChartData mainBarData(List<double> data, bool isDark) {
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double maxY = maxVal == 0 ? 100000 : maxVal * 1.2;

    return BarChartData(
      maxY: maxY,
      minY: 0,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: List.generate(7, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data[i],
              color: Colors.redAccent,
              width: 16,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              ),
            )
          ],
        );
      }),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    List<String> days = userProvider.getText('days').split(',');
    int index = value.toInt();
    if (index < 0 || index >= days.length) return const SizedBox();
    return SideTitleWidget(
        meta: meta,
        child: Text(
          days[index],
          style: TextStyle(
            color: userProvider.isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 11,
          ),
        ));
  }
}