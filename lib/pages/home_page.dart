import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/transaction_buttons.dart';
import '../theme/app_theme.dart';
import '../components/modern_card.dart';
import '../utils/animations.dart';

// Define BalanceCard widget for use in _buildWelcomeSection
class BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const BalanceCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.gradient,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₱${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _gcashBalanceController = TextEditingController();
  final _loadBalanceController = TextEditingController();
  final _topupAmountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _transactionFormKey = GlobalKey();

  double _gcashBalance = 0.0;
  double _loadWalletBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;
  double _monthlyRevenue = 0.0;
  double _dailyIncome = 0.0;
  double _dailyExpense = 0.0;
  double _dailyRevenue = 0.0;
  bool _balancesLoaded = false;
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  final double _mayaCommissionRate = 0.03;
  final double _fixedMarkup = 3.0;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _refreshAnimation = CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut);
    _loadBalances();
    _calculateDailyStats();
  }

  void _calculateDailyStats() {
    final box = Hive.box('transactions');
    final today = DateTime.now();
    final List items = box.values.toList();
    double income = 0.0;
    double expense = 0.0;
    double revenue = 0.0;

    for (var item in items) {
      if (item['date'] == null) continue;
      
      final txDate = DateTime.parse(item['date']);
      if (txDate.year == today.year && 
          txDate.month == today.month && 
          txDate.day == today.day) {
        
        if (item['type'] == 'load') {
          income += (item['customerPays'] as num?)?.toDouble() ?? 0.0;
          expense += (item['deducted'] as num?)?.toDouble() ?? 0.0;
          revenue += (item['profit'] as num?)?.toDouble() ?? 0.0;
        } else {
          final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
          final fee = (item['serviceFee'] as num?)?.toDouble() ?? 0.0;
          
          if (item['type'] == 'gcash_out') {
            income += amount;
            expense -= amount;
            revenue += fee;
          } else if (item['type'] == 'gcash_in') {
            income -= amount;
            expense += amount;
            revenue += fee;
          } else if (item['type'] == 'topup') {
            expense += amount;
          }
        }
      }
    }

    setState(() {
      _dailyIncome = income;
      _dailyExpense = expense;
      _dailyRevenue = revenue;
    });
  }

  double _calculateGcashFee(double amount) {
    if (amount <= 100) return 5;
    if (amount <= 300) return 10;
    if (amount <= 500) return 15;
    if (amount <= 1000) return 25;
    if (amount <= 1500) return 30;
    if (amount <= 2000) return 40;
    if (amount <= 2500) return 50;
    if (amount <= 3000) return 60;
    if (amount <= 3500) return 70;
    if (amount <= 4000) return 80;
    if (amount <= 4500) return 90;
    if (amount <= 5000) return 100;
    if (amount <= 5500) return 110;
    if (amount <= 6000) return 120;
    if (amount <= 6500) return 130;
    if (amount <= 7000) return 140;
    return 0;
  }

  Future<void> _loadBalances() async {
    _refreshController.forward(from: 0);
    final box = Hive.box('balances');
    setState(() {
      _gcashBalance = box.get('gcash', defaultValue: 0.0);
      _loadWalletBalance = box.get('load', defaultValue: 0.0);
      _monthlyIncome = box.get('income', defaultValue: 0.0);
      _monthlyExpense = box.get('expense', defaultValue: 0.0);
      _monthlyRevenue = box.get('revenue', defaultValue: 0.0);
      _balancesLoaded = true;
    });
    _refreshController.reverse();
  }

  Future<void> _saveBalances() async {
    final box = Hive.box('balances');
    await box.put('gcash', _gcashBalance);
    await box.put('load', _loadWalletBalance);
    await box.put('income', _monthlyIncome);
    await box.put('expense', _monthlyExpense);
    await box.put('revenue', _monthlyRevenue);
  }

  void _editBalances() {
    _gcashBalanceController.text = _gcashBalance.toStringAsFixed(2);
    _loadBalanceController.text = _loadWalletBalance.toStringAsFixed(2);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Balances', style: TextStyle(color: Colors.green[700])),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _gcashBalanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'GCash Balance (₱)',
                prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.green[700]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loadBalanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Load (₱)',
                prefixIcon: Icon(Icons.phone_android, color: Colors.green[700]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              if (_gcashBalanceController.text.isNotEmpty &&
                  _loadBalanceController.text.isNotEmpty) {
                setState(() {
                  _gcashBalance = double.parse(_gcashBalanceController.text);
                  _loadWalletBalance = double.parse(_loadBalanceController.text);
                });
                _saveBalances();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Balances updated successfully'),
                    backgroundColor: Colors.green[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(10),
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  void _showTopupDialog(String type) {
    _topupAmountController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          type == 'gcash' ? 'GCash Top-up' : 'Load Wallet Top-up',
          style: TextStyle(color: Colors.green[700]),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _topupAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (₱)',
                prefixIcon: Icon(Icons.attach_money, color: Colors.green[700]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: type == 'gcash' ? Colors.blue[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: type == 'gcash' ? Colors.blue[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: type == 'gcash' ? Colors.blue[800] : Colors.orange[800],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      type == 'gcash'
                          ? 'This will add to your GCash balance using your income.'
                          : 'This will deduct from your GCash balance to add to your Load Wallet.',
                      style: TextStyle(
                        color: type == 'gcash' ? Colors.blue[800] : Colors.orange[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () => _handleTopup(type),
            child: const Text('Complete Top-up', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTopup(String type) {
    final amount = double.tryParse(_topupAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }

    final box = Hive.box('transactions');

    if (type == 'load') {
      if (_gcashBalance >= amount) {
        box.add({
          'type': 'topup',
          'amount': amount,
          'serviceFee': 0.0,
          'totalAmount': amount,
          'date': DateTime.now().toIso8601String(),
          'wallet': 'load',
        });

        setState(() {
          _loadWalletBalance += amount;
          _gcashBalance -= amount;
          _monthlyExpense += amount;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Insufficient GCash balance for top-up!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
        return;
      }
    } else {
      box.add({
        'type': 'gcash_topup',
        'amount': amount,
        'serviceFee': 0.0,
        'totalAmount': amount,
        'date': DateTime.now().toIso8601String(),
      });

      setState(() {
        _gcashBalance += amount;
        _monthlyIncome -= amount;
      });
    }

    _saveBalances();
    _calculateDailyStats();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${type == 'gcash' ? 'GCash' : 'Load wallet'} top-up completed successfully!'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  void dispose() {
    _gcashBalanceController.dispose();
    _loadBalanceController.dispose();
    _topupAmountController.dispose();
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTransactionForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transactionFormKey.currentContext != null) {
        Scrollable.ensureVisible(
          _transactionFormKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'FinSync',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: AppTheme.textPrimary),
          onPressed: _loadBalances,
          tooltip: 'Refresh data',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surfaceColor,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.tune_rounded, color: AppTheme.textPrimary),
          onPressed: _editBalances,
          tooltip: 'Settings',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surfaceColor,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  void _calculateStatsForDate(DateTime date) {
    final box = Hive.box('transactions');
    final List items = box.values.toList();
    double income = 0.0;
    double expense = 0.0;
    double revenue = 0.0;

    for (var item in items) {
      if (item['date'] == null) continue;
      
      final txDate = DateTime.parse(item['date']);
      if (txDate.year == date.year && 
          txDate.month == date.month && 
          txDate.day == date.day) {
        
        if (item['type'] == 'load') {
          income += (item['customerPays'] as num?)?.toDouble() ?? 0.0;
          expense += (item['deducted'] as num?)?.toDouble() ?? 0.0;
          revenue += (item['profit'] as num?)?.toDouble() ?? 0.0;
        } else {
          final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
          final fee = (item['serviceFee'] as num?)?.toDouble() ?? 0.0;
          
          if (item['type'] == 'gcash_out') {
            income += amount;
            expense -= amount;
            revenue += fee;
          } else if (item['type'] == 'gcash_in') {
            income -= amount;
            expense += amount;
            revenue += fee;
          } else if (item['type'] == 'topup') {
            expense += amount;
          }
        }
      }
    }

    setState(() {
      _dailyIncome = income;
      _dailyExpense = expense;
      _dailyRevenue = revenue;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_balancesLoaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green[700]),
              const SizedBox(height: 16),
              Text('Loading your data...', style: TextStyle(color: Colors.green[700])),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final formatter = DateFormat('MMMM dd, yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: _buildAppBar(),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () {
            _scrollController.animateTo(
              400,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          backgroundColor: AppTheme.primaryColor,
          elevation: 8,
          tooltip: 'Quick Transactions',
          child: BouncingIcon(
            icon: Icons.bolt_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: RefreshIndicator(
        onRefresh: _loadBalances,
        color: Colors.green[700],
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimationUtils.fadeIn(
                duration: const Duration(milliseconds: 800),
                child: _buildWelcomeSection(now, formatter, timeFormatter),
              ),
              const SizedBox(height: 24),
              TransactionButtons(
                key: _transactionFormKey,
                onTransactionSaved: () {
                  _loadBalances();
                  _calculateDailyStats();
                },
                gcashBalance: _gcashBalance,
                loadWalletBalance: _loadWalletBalance,
              ),
              const SizedBox(height: 20),
              AnimationUtils.slideInFromLeft(
                duration: const Duration(milliseconds: 1000),
                child: ModernCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                      ),
                                      child: const Icon(
                                        Icons.trending_up_rounded,
                                        color: AppTheme.successColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedDate == null
                                          ? 'Today\'s Cash Flow'
                                          : 'Cash Flow for ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Track your daily income and expenses',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.calendar_today, color: Colors.green[700]),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Colors.green[700]!,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: Colors.black,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDate = picked;
                                      _calculateStatsForDate(_selectedDate!);
                                    });
                                  }
                                },
                                tooltip: 'Select Date',
                              ),
                              if (_selectedDate != null)
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red[700]),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = null;
                                      _calculateDailyStats();
                                    });
                                  },
                                  tooltip: 'Clear Date Filter',
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildCashFlowSection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimationUtils.slideInFromBottom(
                duration: const Duration(milliseconds: 1100),
                child: ModernCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedDate != null
                                          ? 'Transactions for ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}'
                                          : 'Today\'s Transactions',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Recent activity overview',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTransactionsList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashFlowItem({
    required String title,
    required double amount,
    required IconData icon,
    required bool isIncome,
  }) {
    final color = isIncome ? AppTheme.successColor : AppTheme.errorColor;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: amount,
            prefix: '₱',
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('transactions').listenable(),
      builder: (context, box, _) {
        final dateToFilter = _selectedDate ?? DateTime.now();
        final items = box.values.toList().reversed.where((item) {
          if (item['date'] == null) return false;
          final txDate = DateTime.parse(item['date']);
          return txDate.year == dateToFilter.year &&
                 txDate.month == dateToFilter.month &&
                 txDate.day == dateToFilter.day;
        }).toList();

        if (items.isEmpty) {
          String dateString = _selectedDate == null 
            ? "today" 
            : "for ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}";
          String subMessage = _selectedDate == null
            ? "Your today's transactions will appear here"
            : "Transactions for this date will appear here";

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No transactions $dateString',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  subMessage,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Column(
          children: items.map((item) {
            if (item['type'] == 'load') {
              return _buildLoadTransactionItem(item);
            } else {
              return _buildTransactionItem(item);
            }
          }).toList(),
        );
      },
    );
  }

  Widget _buildCashFlowSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCashFlowItem(
                title: 'Income',
                amount: _dailyIncome,
                icon: Icons.arrow_downward,
                isIncome: true,
              ),
            ),
            Expanded(
              child: _buildCashFlowItem(
                title: 'Expense',
                amount: _dailyExpense,
                icon: Icons.arrow_upward,
                isIncome: false,
              ),
            ),
            Expanded(
              child: _buildCashFlowItem(
                title: 'Revenue',
                amount: _dailyRevenue,
                icon: Icons.trending_up,
                isIncome: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<dynamic, dynamic> item) {
    String typeLabel;
    IconData typeIcon;
    bool isIncome = false;
    Color iconColor;
    double displayAmount = item['amount'] is num ? item['amount'].toDouble() : 0.0;
    final date = DateTime.parse(item['date']);
    final formattedTime = DateFormat('hh:mm a').format(date);

    switch (item['type']) {
      case 'gcash_in':
        typeLabel = 'Cash In';
        typeIcon = Icons.arrow_upward;
        iconColor = Colors.red[700]!;
        isIncome = false;
        break;
      case 'gcash_out':
        typeLabel = 'Cash Out';
        typeIcon = Icons.arrow_downward;
        iconColor = Colors.green[700]!;
        isIncome = true;
        break;
      case 'topup':
        typeLabel = 'Load Wallet Top-up';
        typeIcon = Icons.add_circle_outline;
        iconColor = Colors.orange[700]!;
        isIncome = false;
        break;
      case 'gcash_topup':
        typeLabel = 'GCash Top-up';
        typeIcon = Icons.account_balance_wallet;
        iconColor = Colors.blue[700]!;
        isIncome = true;
        break;
      default:
        typeLabel = item['type'];
        typeIcon = Icons.swap_horiz;
        iconColor = Colors.grey[700]!;
        isIncome = false;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item['type'] == 'gcash_topup' ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item['type'] == 'gcash_topup' ? Colors.blue[200]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              typeIcon,
              color: iconColor,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800]),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (item['type'] == 'gcash_topup') ...[
                  const SizedBox(height: 4),
                  Text(
                    'From Income',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  (isIncome ? '+' : '-') + '₱${displayAmount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isIncome ? Colors.green[700] : Colors.red[700],
                  ),
                  maxLines: 1,
                ),
              ),
              if (item['serviceFee'] != null && item['serviceFee'] > 0) ...[
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Fee: ₱${item['serviceFee'].toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadTransactionItem(Map<dynamic, dynamic> item) {
    final date = DateTime.parse(item['date']);
    final formattedTime = DateFormat('hh:mm a').format(date);
    final customerPays = item['customerPays'] is num ? item['customerPays'].toDouble() : 0.0;
    final deducted = item['deducted'] is num ? item['deducted'].toDouble() : 0.0;
    final profit = item['profit'] is num ? item['profit'].toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_android,
                  color: Colors.purple[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Load',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+₱${customerPays.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Profit: ₱${profit.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.purple[200]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wallet Deducted:',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '-₱${deducted.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[700]),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commission:',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '-₱${(item['commission'] ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(DateTime now, DateFormat formatter, DateFormat timeFormatter) {
    return ModernCard(
      gradient: AppTheme.primaryGradient,
      boxShadow: AppTheme.elevatedShadow,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello there! 👋',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatter.format(now),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your finances with ease',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Current Balances',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AnimationUtils.slideInFromLeft(
                  duration: const Duration(milliseconds: 600),
                  child: BalanceCard(
                    title: 'GCash',
                    amount: _gcashBalance,
                    icon: Icons.account_balance_wallet_rounded,
                    gradient: AppTheme.accentGradient,
                    onTap: () => _showTopupDialog('gcash'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimationUtils.slideInFromBottom(
                  duration: const Duration(milliseconds: 700),
                  child: BalanceCard(
                    title: 'Load',
                    amount: _loadWalletBalance,
                    icon: Icons.phone_android_rounded,
                    gradient: AppTheme.successGradient,
                    onTap: () => _showTopupDialog('load'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Last updated: ${timeFormatter.format(now)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}