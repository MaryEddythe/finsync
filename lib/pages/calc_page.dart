import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CalcPage extends StatefulWidget {
  @override
  _CalcPageState createState() => _CalcPageState();
}

class _CalcPageState extends State<CalcPage> {
  final TextEditingController _amountController = TextEditingController();
  double _serviceFee = 0.0;
  double _totalAmount = 0.0;
  bool _showFeeTable = false;
  final String _userName = "Idit"; 
  final DateTime _lastUpdated = DateTime.now();

  void _calculateFee() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    if (amount <= 0) {
      setState(() {
        _serviceFee = 0.0;
        _totalAmount = 0.0;
      });
      return;
    }

    double fee;
    if (amount <= 100) {
      fee = 5;
    } else if (amount <= 300) {
      fee = 10;
    } else if (amount <= 500) {
      fee = 15;
    } else if (amount <= 1000) {
      fee = 25;
    } else if (amount <= 1500) {
      fee = 35;
    } else if (amount <= 2000) {
      fee = 45;
    } else if (amount <= 2500) {
      fee = 50;
    } else if (amount <= 3000) {
      fee = 60;
    } else if (amount <= 3500) {
      fee = 70;
    } else if (amount <= 4000) {
      fee = 80;
    } else if (amount <= 4500) {
      fee = 90;
    } else if (amount <= 5000) {
      fee = 100;
    } else if (amount <= 5500) {
      fee = 110;
    } else if (amount <= 6000) {
      fee = 120;
    } else if (amount <= 6500) {
      fee = 130;
    } else if (amount <= 7000) {
      fee = 140;
    } else {
      fee = 0;
    }

    setState(() {
      _serviceFee = fee;
      _totalAmount = amount + fee;
    });
  }

  // Calculate today's service fee revenue
  double _calculateTodayServiceFeeRevenue() {
    final transactionsBox = Hive.box('transactions');
    final today = DateTime.now();
    double todayRevenue = 0.0;
    
    final transactions = transactionsBox.values.where((e) {
      if (e['date'] == null) return false;
      final date = DateTime.parse(e['date']);
      return date.year == today.year && 
             date.month == today.month && 
             date.day == today.day;
    });
    
    for (var transaction in transactions) {
      if (transaction['serviceFee'] != null) {
        todayRevenue += (transaction['serviceFee'] as num).toDouble();
      }
    }
    
    return todayRevenue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = Colors.teal[700]; // Soft green-blue inspired by design
    final accentColor = Colors.blue[700];
    final surfaceColor = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.teal[50], // Soft background inspired by design
      appBar: AppBar(
        title: Text('GCash Finance Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About', style: TextStyle(color: primaryColor)),
                  content: Text('Track your GCash transactions and calculate service fees.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK', style: TextStyle(color: primaryColor)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $_userName!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Track your GCash transactions',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: primaryColor),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            ValueListenableBuilder(
              valueListenable: Hive.box('balances').listenable(),
              builder: (context, balanceBox, _) {
                final gcashBalance = balanceBox.get('gcash', defaultValue: 0.0);
                final todayServiceFeeRevenue = _calculateTodayServiceFeeRevenue();
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      title: 'GCash Balance',
                      value: '₱${gcashBalance.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet,
                    ),
                    _buildStatCard(
                      title: 'Today\'s Revenue',
                      value: '₱${todayServiceFeeRevenue.toStringAsFixed(2)}',
                      icon: Icons.monetization_on,
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 20),

            // Calculator Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GCash Load Calculator',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        prefixText: '₱',
                        prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDarkMode ? surfaceColor.withOpacity(0.5) : Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        hintText: 'Enter amount',
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                        suffixIcon: _amountController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _amountController.clear();
                                  _calculateFee();
                                },
                              )
                            : null,
                      ),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.end,
                      onChanged: (value) => _calculateFee(),
                    ),
                    SizedBox(height: 20),
                    SizedBox(height: 20),
                    _buildResultRow('Amount', '₱${_amountController.text.isEmpty ? '0.00' : double.tryParse(_amountController.text)?.toStringAsFixed(2) ?? '0.00'}'),
                    Divider(height: 24, thickness: 1),
                    _buildResultRow('Service Fee', '-₱${_serviceFee.toStringAsFixed(2)}', isFee: true),
                    Divider(height: 24, thickness: 1),
                    _buildResultRow('Total', '₱${_totalAmount.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Fee Table Toggle
            OutlinedButton.icon(
              icon: Icon(_showFeeTable ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: primaryColor),
              label: Text(_showFeeTable ? 'Hide Fee Structure' : 'Show Fee Structure', style: TextStyle(color: primaryColor)),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: primaryColor ?? Colors.teal),
              ),
              onPressed: () {
                setState(() {
                  _showFeeTable = !_showFeeTable;
                });
              },
            ),
            SizedBox(height: 12),

            if (_showFeeTable)
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'GCash Fee Structure',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
                            ),
                            Text(
                              'Last Updated: ${_lastUpdated.toString().substring(0, 16)}',
                              style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6)),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 24,
                            columns: [
                              DataColumn(label: Text('Amount Range (₱)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Fee (₱)', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _buildFeeTableRows(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon}) {
    return Expanded(
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Colors.teal[700]),
                  SizedBox(width: 8),
                  Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isFee = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: isFee ? Colors.red : isTotal ? Colors.teal[700] : Colors.black,
          ),
        ),
      ],
    );
  }

  List<DataRow> _buildFeeTableRows() {
    return [
      _buildFeeTableRow('1 - 100', '5'),
      _buildFeeTableRow('101 - 300', '10'),
      _buildFeeTableRow('301 - 500', '15'),
      _buildFeeTableRow('501 - 1,000', '25'),
      _buildFeeTableRow('1,001 - 1,500', '35'),
      _buildFeeTableRow('1,501 - 2,000', '45'),
      _buildFeeTableRow('2,001 - 2,500', '50'),
      _buildFeeTableRow('2,501 - 3,000', '60'),
      _buildFeeTableRow('3,001 - 3,500', '70'),
      _buildFeeTableRow('3,501 - 4,000', '80'),
      _buildFeeTableRow('4,001 - 4,500', '90'),
      _buildFeeTableRow('4,501 - 5,000', '100'),
      _buildFeeTableRow('5,001 - 5,500', '110'),
      _buildFeeTableRow('5,501 - 6,000', '120'),
      _buildFeeTableRow('6,001 - 6,500', '130'),
      _buildFeeTableRow('6,501 - 7,000', '140'),
    ];
  }

  DataRow _buildFeeTableRow(String range, String fee) {
    final isCurrentRange = _isInCurrentRange(range);
    return DataRow(
      cells: [
        DataCell(Text(range, style: TextStyle(fontWeight: isCurrentRange ? FontWeight.bold : FontWeight.normal))),
        DataCell(Text(fee, style: TextStyle(fontWeight: isCurrentRange ? FontWeight.bold : FontWeight.normal))),
      ],
    );
  }

  bool _isInCurrentRange(String range) {
    if (_amountController.text.isEmpty) return false;
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return false;

    final rangeParts = range.split(' - ');
    if (rangeParts.length != 2) return false;

    final min = double.tryParse(rangeParts[0].replaceAll(',', '')) ?? 0.0;
    final max = double.tryParse(rangeParts[1].replaceAll(',', '')) ?? 0.0;

    return amount >= min && amount <= max;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}