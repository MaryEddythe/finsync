import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('transactions');
  await Hive.openBox('balances');
  runApp(MaterialApp(
    title: 'GCash & Load Tracker',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  String _transactionType = 'gcash_in';
  final _amountController = TextEditingController();
  final _customerPaysController = TextEditingController();
  final _walletDeductedController = TextEditingController();
  final _gcashBalanceController = TextEditingController();
  final _loadBalanceController = TextEditingController();

  double _gcashBalance = 0.0;
  double _loadWalletBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    final box = Hive.box('balances');
    setState(() {
      _gcashBalance = box.get('gcash', defaultValue: 0.0);
      _loadWalletBalance = box.get('load', defaultValue: 0.0);
      _monthlyIncome = box.get('income', defaultValue: 0.0);
      _monthlyExpense = box.get('expense', defaultValue: 0.0);
    });
  }

  Future<void> _saveBalances() async {
    final box = Hive.box('balances');
    await box.put('gcash', _gcashBalance);
    await box.put('load', _loadWalletBalance);
    await box.put('income', _monthlyIncome);
    await box.put('expense', _monthlyExpense);
  }

  void _editBalances() {
    _gcashBalanceController.text = _gcashBalance.toStringAsFixed(2);
    _loadBalanceController.text = _loadWalletBalance.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Balances'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _gcashBalanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'GCash Balance (₱)'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter amount';
                if (double.tryParse(value) == null) return 'Enter valid number';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _loadBalanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Load Wallet Balance (₱)'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter amount';
                if (double.tryParse(value) == null) return 'Enter valid number';
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
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
              }
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  void _saveTransaction() {
    if (_transactionType != 'load') {
      if (_formKey.currentState!.validate()) {
        final amount = double.tryParse(_amountController.text);
        if (amount != null) {
          final box = Hive.box('transactions');
          box.add({
            'type': _transactionType,
            'amount': amount,
            'date': DateTime.now().toIso8601String(),
          });
          
          setState(() {
            if (_transactionType == 'gcash_in') {
              _gcashBalance += amount;
              _monthlyIncome += amount;
            } else if (_transactionType == 'gcash_out') {
              _gcashBalance -= amount;
              _monthlyExpense += amount;
            } else if (_transactionType == 'topup') {
              _loadWalletBalance += amount;
            }
          });
          
          _amountController.clear();
          _saveBalances();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transaction saved!')),
          );
        }
      }
    }
  }

  void _saveLoadTransaction() {
    final customerPays = double.tryParse(_customerPaysController.text);
    final walletDeducted = double.tryParse(_walletDeductedController.text);

    if (customerPays != null && walletDeducted != null) {
      final profit = customerPays - walletDeducted;
      final box = Hive.box('transactions');
      box.add({
        'type': 'load',
        'customerPays': customerPays,
        'deducted': walletDeducted,
        'profit': profit,
        'date': DateTime.now().toIso8601String(),
      });

      setState(() {
        _loadWalletBalance -= walletDeducted;
        _gcashBalance += customerPays;
        _monthlyIncome += customerPays;
      });

      _customerPaysController.clear();
      _walletDeductedController.clear();
      _saveBalances();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load transaction saved!')),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customerPaysController.dispose();
    _walletDeductedController.dispose();
    _gcashBalanceController.dispose();
    _loadBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: _editBalances,
        child: Icon(Icons.edit),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
              color: Colors.blue[700],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GCash & Load Tracker', 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('Track your transactions and balances', 
                      style: TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),

            // Balance Section
            _buildBalanceSection(),

            // Cash Flow Section
            _buildCashFlowSection(),

            // Transaction Form Section
            _buildTransactionFormSection(),

            // Recent Transactions Section
            _buildRecentTransactionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wallet Balances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadBalances,
                tooltip: 'Refresh balances',
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceCard(
                title: 'GCash Balance',
                amount: _gcashBalance,
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
              ),
              _buildBalanceCard(
                title: 'Load Wallet',
                amount: _loadWalletBalance,
                icon: Icons.phone_android,
                color: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 16),
          Text('Updated just now', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({required String title, required double amount, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
            SizedBox(height: 8),
            Text('₱${amount.toStringAsFixed(2)}', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowSection() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCashFlowItem(
                title: 'Income',
                amount: _monthlyIncome,
                isIncome: true,
              ),
              _buildCashFlowItem(
                title: 'Expense',
                amount: _monthlyExpense,
                isIncome: false,
              ),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: _monthlyIncome > 0 ? _monthlyExpense / _monthlyIncome : 0,
            backgroundColor: Colors.red[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 8),
          Text(
            'Cash Flow: ₱${(_monthlyIncome - _monthlyExpense).toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: (_monthlyIncome - _monthlyExpense) >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowItem({required String title, required double amount, required bool isIncome}) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey)),
        SizedBox(height: 4),
        Text('₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            )),
      ],
    );
  }

  Widget _buildTransactionFormSection() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _transactionType,
              items: [
                DropdownMenuItem(value: 'gcash_in', child: Text('GCash Cash In')),
                DropdownMenuItem(value: 'gcash_out', child: Text('GCash Cash Out')),
                DropdownMenuItem(value: 'load', child: Text('Load Sold')),
                DropdownMenuItem(value: 'topup', child: Text('Load Wallet Top-up')),
              ],
              onChanged: (val) {
                setState(() {
                  _transactionType = val!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Transaction Type',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            
            if (_transactionType != 'load') ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₱)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null) return 'Enter valid number';
                  return null;
                },
              ),
            ] else ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _customerPaysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Customer Pays (₱)',
                  hintText: 'e.g. 53 for GIGA50',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null) return 'Enter valid number';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _walletDeductedController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Wallet Deducted (₱)',
                  hintText: 'e.g. 47.97 for GIGA50',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null) return 'Enter valid number';
                  return null;
                },
              ),
            ],
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _transactionType == 'load' ? _saveLoadTransaction : _saveTransaction,
              child: Text(_transactionType == 'load' ? 'Log Load Transaction' : 'Log Transaction'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), backgroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: Text('View All', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
          SizedBox(height: 16),
          _transactionType == 'load' 
              ? _buildLoadTransactionList()
              : _buildTodayTransactionList(),
        ],
      ),
    );
  }

  Widget _buildTodayTransactionList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('transactions').listenable(),
      builder: (context, box, _) {
        final today = DateTime.now();
        final items = box.values.where((e) {
          final date = DateTime.parse(e['date']);
          return e['type'] != 'load' &&
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).toList().reversed.take(5).toList();

        if (items.isEmpty) {
          return Center(child: Text('No transactions today', style: TextStyle(color: Colors.grey)));
        }
        return Column(
          children: items.map((item) => _buildTransactionItem(item)).toList(),
        );
      },
    );
  }

  Widget _buildLoadTransactionList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('transactions').listenable(),
      builder: (context, box, _) {
        final today = DateTime.now();
        final items = box.values.where((e) {
          final date = DateTime.parse(e['date']);
          return e['type'] == 'load' &&
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).toList().reversed.take(5).toList();

        if (items.isEmpty) {
          return Center(child: Text('No load transactions today', style: TextStyle(color: Colors.grey)));
        }
        return Column(
          children: items.map((item) => _buildLoadTransactionItem(item)).toList(),
        );
      },
    );
  }

  Widget _buildTransactionItem(Map<dynamic, dynamic> item) {
    String typeLabel;
    bool isIncome = false;
    
    switch (item['type']) {
      case 'gcash_in':
        typeLabel = 'GCash Cash In';
        isIncome = true;
        break;
      case 'gcash_out':
        typeLabel = 'GCash Cash Out';
        isIncome = false;
        break;
      case 'topup':
        typeLabel = 'Load Top-up';
        isIncome = true;
        break;
      default:
        typeLabel = item['type'];
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isIncome ? Colors.green[50] : Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeLabel, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  DateTime.parse(item['date']).toString().substring(0, 16),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '₱${item['amount'].toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadTransactionItem(Map<dynamic, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Load Sale', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '₱${item['customerPays'].toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deducted: ₱${item['deducted'].toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                'Profit: ₱${item['profit'].toStringAsFixed(2)}',
                style: TextStyle(
                  color: item['profit'] >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            DateTime.parse(item['date']).toString().substring(0, 16),
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}