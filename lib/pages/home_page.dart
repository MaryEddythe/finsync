import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('transactions');
  await Hive.openBox('balances');
  runApp(MaterialApp(
    title: 'GCash & Load Tracker V2',
    theme: ThemeData(
      primarySwatch: Colors.green,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: GoogleFonts.poppinsTextTheme(),
      useMaterial3: true,
    ),
    home: HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _transactionType = 'gcash_in';
  final _amountController = TextEditingController();
  final _customerPaysController = TextEditingController();
  final _walletDeductedController = TextEditingController();
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
  
  bool _showTransactionForm = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _refreshAnimation = CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut);
    _customerPaysController.addListener(_autoCalculateWalletDeducted);
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
            income -= amount;
            expense += amount;
            revenue += fee;
          } else if (item['type'] == 'gcash_in') {
            income += (amount + fee);
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
    if (amount <= 1500) return 35;
    if (amount <= 2000) return 45;
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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
            SizedBox(height: 16),
            TextFormField(
              controller: _loadBalanceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                    content: Text('Balances updated successfully'),
                    backgroundColor: Colors.green[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: EdgeInsets.all(10),
                  ),
                );
              }
            },
            child: Text('Save', style: TextStyle(color: Colors.white)),
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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
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
                  SizedBox(width: 8),
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
            child: Text('Complete Top-up', style: TextStyle(color: Colors.white)),
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
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
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
            content: Text('Insufficient GCash balance for top-up!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
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
        margin: EdgeInsets.all(10),
      ),
    );
  }

  void _saveTransaction() {
    if (_transactionType != 'load') {
      if (_formKey.currentState!.validate()) {
        final amount = double.tryParse(_amountController.text);
        if (amount != null) {
          double fee = _calculateGcashFee(amount);
          final box = Hive.box('transactions');
          
          if (_transactionType == 'gcash_in') {
            if (_gcashBalance >= amount) {
              box.add({
                'type': _transactionType,
                'amount': amount,
                'serviceFee': fee,
                'totalAmount': amount + fee,
                'date': DateTime.now().toIso8601String(),
              });

              setState(() {
                _gcashBalance -= amount;
                _monthlyIncome += (amount + fee);
                _monthlyExpense += amount;
                _monthlyRevenue += fee;
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Insufficient GCash balance for cash-in!'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: EdgeInsets.all(10),
                ),
              );
              return;
            }
          } 
          else if (_transactionType == 'gcash_out') {
            box.add({
              'type': _transactionType,
              'amount': amount,
              'serviceFee': fee,
              'totalAmount': amount + fee,
              'date': DateTime.now().toIso8601String(),
            });

            setState(() {
              _gcashBalance += amount;
              _monthlyIncome -= amount; // Subtract cash out from income
              _monthlyExpense += amount;
              _monthlyRevenue += fee;
            });
          }
          
          _amountController.clear();
          _saveBalances();
          _calculateDailyStats();
          
          setState(() {
            _showTransactionForm = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction saved! Fee: ₱${fee.toStringAsFixed(2)}'),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.all(10),
            ),
          );
        }
      }
    }
  }

  void _saveLoadTransaction() {
    final customerPays = double.tryParse(_customerPaysController.text);
    final walletDeducted = double.tryParse(_walletDeductedController.text);
    if (customerPays != null && walletDeducted != null) {
      if (_loadWalletBalance < walletDeducted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient load wallet balance!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
          ),
        );
        return;
      }
      
      final mayaCommission = walletDeducted * _mayaCommissionRate;
      final profit = customerPays - walletDeducted;
      
      final box = Hive.box('transactions');
      box.add({
        'type': 'load',
        'customerPays': customerPays,
        'deducted': walletDeducted,
        'commission': mayaCommission,
        'profit': profit,
        'date': DateTime.now().toIso8601String(),
      });

      setState(() {
        _loadWalletBalance -= walletDeducted;
        _monthlyIncome += customerPays;
        _monthlyExpense += walletDeducted;
        _monthlyRevenue += profit;
      });

      _customerPaysController.clear();
      _walletDeductedController.clear();
      _saveBalances();
      _calculateDailyStats();
      
      setState(() {
        _showTransactionForm = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Load transaction saved! Profit: ₱${profit.toStringAsFixed(2)}'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  void _autoCalculateWalletDeducted() {
    if (_transactionType == 'load') {
      final customerPays = double.tryParse(_customerPaysController.text);
      if (customerPays != null && customerPays > 0) {
        final walletDeducted = (customerPays - _fixedMarkup) / (1 + _mayaCommissionRate);
        if (!_walletDeductedController.text.contains('.') ||
            double.tryParse(_walletDeductedController.text) == null ||
            _walletDeductedController.text.isEmpty ||
            _walletDeductedController.text == '0') {
          _walletDeductedController.text = walletDeducted.toStringAsFixed(2);
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customerPaysController.dispose();
    _walletDeductedController.dispose();
    _gcashBalanceController.dispose();
    _loadBalanceController.dispose();
    _topupAmountController.dispose();
    _refreshController.dispose();
    _scrollController.dispose();
    _customerPaysController.removeListener(_autoCalculateWalletDeducted);
    super.dispose();
  }

  void _scrollToTransactionForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transactionFormKey.currentContext != null) {
        Scrollable.ensureVisible(
          _transactionFormKey.currentContext!,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.green[700],
      elevation: 0,
      title: Text(
        'GCash & Load Tracker V2',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadBalances,
          tooltip: 'Refresh data',
        ),
        IconButton(
          icon: Icon(Icons.edit, color: Colors.white),
          onPressed: _editBalances,
          tooltip: 'Edit balances',
        ),
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
            income -= amount;
            expense += amount;
            revenue += fee;
          } else if (item['type'] == 'gcash_in') {
            income += (amount + fee);
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
              SizedBox(height: 16),
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
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _showTransactionForm = !_showTransactionForm;
            if (_showTransactionForm) {
              _scrollToTransactionForm();
            }
          });
        },
        icon: Icon(_showTransactionForm ? Icons.close : Icons.add, color: Colors.white),
        label: Text(_showTransactionForm ? 'Close' : 'New Transaction', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: RefreshIndicator(
        onRefresh: _loadBalances,
        color: Colors.green[700],
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting and Date Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, Idit!',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 4),
                            Text(
                              formatter.format(now),
                              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Colors.green[700]),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Current Balances',
                      style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceCard(
                            title: 'GCash',
                            amount: _gcashBalance,
                            icon: Icons.account_balance_wallet,
                            color: Colors.white,
                            bgColor: Colors.white.withOpacity(0.2),
                            onTopup: () => _showTopupDialog('gcash'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildBalanceCard(
                            title: 'Load',
                            amount: _loadWalletBalance,
                            icon: Icons.phone_android,
                            color: Colors.white,
                            bgColor: Colors.white.withOpacity(0.2),
                            onTopup: () => _showTopupDialog('load'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Last updated: ${timeFormatter.format(now)}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Cash Flow Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'Today\'s Cash Flow'
                                : 'Cash Flow for ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
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
                    SizedBox(height: 16),
                    _buildCashFlowSection(),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Transaction Form Section (Collapsible)
              AnimatedContainer(
                key: _transactionFormKey,
                duration: Duration(milliseconds: 300),
                height: _showTransactionForm ? null : 0,
                curve: Curves.easeInOut,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _showTransactionForm
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))]
                      : null,
                ),
                child: _showTransactionForm
                    ? Padding(
                        padding: EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Transaction',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _transactionType,
                                    isExpanded: true,
                                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.green[700]),
                                    items: [
                                      DropdownMenuItem(value: 'gcash_in', child: _buildDropdownItem(Icons.arrow_upward, 'GCash Cash In')),
                                      DropdownMenuItem(value: 'gcash_out', child: _buildDropdownItem(Icons.arrow_downward, 'GCash Cash Out')),
                                      DropdownMenuItem(value: 'load', child: _buildDropdownItem(Icons.phone_android, 'Load Sold')),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _transactionType = val!;
                                      });
                                    },
                                    dropdownColor: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              if (_transactionType != 'load') ...[
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Amount (₱)',
                                    hintText: 'Enter amount',
                                    prefixIcon: Icon(Icons.attach_money, color: Colors.green[700]),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Enter amount';
                                    if (double.tryParse(value) == null) return 'Enter valid number';
                                    return null;
                                  },
                                  onChanged: (value) {
                                    if (value.isNotEmpty && (_transactionType == 'gcash_in' || _transactionType == 'gcash_out')) {
                                      setState(() {});
                                    }
                                  },
                                ),
                                if (_transactionType == 'gcash_in' || _transactionType == 'gcash_out') ...[
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Service Fee: ₱${_calculateGcashFee(double.tryParse(_amountController.text) ?? 0.0).toStringAsFixed(2)}',
                                            style: TextStyle(color: Colors.amber[800], fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ] else ...[
                                TextFormField(
                                  controller: _customerPaysController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Customer Pays (₱)',
                                    hintText: 'e.g. 53 for GIGA50',
                                    prefixIcon: Icon(Icons.payments, color: Colors.green[700]),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Enter amount';
                                    if (double.tryParse(value) == null) return 'Enter valid number';
                                    return null;
                                  },
                                  onChanged: (val) {
                                    _autoCalculateWalletDeducted();
                                  },
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _walletDeductedController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Wallet Deducted (₱)',
                                    hintText: 'Auto-calculated, but editable',
                                    prefixIcon: Icon(Icons.remove_circle_outline, color: Colors.red[700]),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Enter amount';
                                    if (double.tryParse(value) == null) return 'Enter valid number';
                                    return null;
                                  },
                                ),
                                SizedBox(height: 8),
                                if (_customerPaysController.text.isNotEmpty && _walletDeductedController.text.isNotEmpty) ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: Colors.green[800]),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Estimated Profit: ₱${(double.tryParse(_customerPaysController.text) ?? 0.0) - (double.tryParse(_walletDeductedController.text) ?? 0.0)}',
                                            style: TextStyle(color: Colors.green[800], fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _transactionType == 'load' ? _saveLoadTransaction : _saveTransaction,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      _transactionType == 'load' ? 'Log Load Transaction' : 'Log Transaction',
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 50),
                                  backgroundColor: Colors.green[700],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 6,
                                  shadowColor: Colors.green[900]?.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ),
              SizedBox(height: 24),

              // Recent Transactions Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? 'Transactions for ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}'
                                : 'Today\'s Transactions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildTransactionsList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      );
  }

  Widget _buildDropdownItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green[700]),
        SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTopup,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
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
                  Icon(icon, size: 20, color: color),
                  SizedBox(width: 8),
                  Text(title, style: TextStyle(fontSize: 14, color: color.withOpacity(0.9))),
                ],
              ),
              GestureDetector(
                onTap: onTopup,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowItem({
    required String title,
    required double amount,
    required IconData icon,
    required bool isIncome,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isIncome ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isIncome ? Colors.green[100] : Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isIncome ? Colors.green[700] : Colors.red[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green[700] : Colors.red[700],
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
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  'No transactions $dateString',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(subMessage,
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
          }).toList()
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
        typeLabel = 'GCash Cash In';
        typeIcon = Icons.arrow_upward;
        iconColor = Colors.red[700]!;
        isIncome = false;
        break;
      case 'gcash_out':
        typeLabel = 'GCash Cash Out';
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
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item['type'] == 'gcash_topup' ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item['type'] == 'gcash_topup' ? Colors.blue[200]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              typeIcon,
              color: iconColor,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800]),
                ),
                SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (item['type'] == 'gcash_topup') ...[
                  SizedBox(height: 4),
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
              Text(
                (isIncome ? '+' : '-') + '₱${displayAmount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isIncome ? Colors.green[700] : Colors.red[700],
                ),
              ),
              if (item['serviceFee'] != null && item['serviceFee'] > 0) ...[
                SizedBox(height: 4),
                Text(
                  'Fee: ₱${item['serviceFee'].toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
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
                padding: EdgeInsets.all(10),
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
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Load Sale',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800]),
                    ),
                    SizedBox(height: 4),
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
                  Text(
                    '+₱${customerPays.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Profit: ₱${profit.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Divider(height: 1, color: Colors.purple[200]),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wallet Deducted:',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                '-₱${deducted.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[700]),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commission:',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                '-₱${(item['commission'] ?? 0).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}