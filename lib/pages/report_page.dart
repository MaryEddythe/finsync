import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<Map> _gcashReports = [];
  List<Map> _loadWalletReports = [];
  List<Map> _allReports = [];
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final transactionsBox = Hive.box('transactions');
    final allTransactions = transactionsBox.values.toList();

    List<Map> gcashReports = [];
    List<Map> loadWalletReports = [];
    List<Map> allReports = [];
    double totalIncome = 0.0;
    double totalExpenses = 0.0;

    for (var tx in allTransactions) {
      allReports.add(Map<String, dynamic>.from(tx));

      if (tx['type'] == 'gcash_in' || tx['type'] == 'gcash_topup') {
        gcashReports.add(Map<String, dynamic>.from(tx));
        totalIncome += (tx['amount'] ?? 0.0);
      } else if (tx['type'] == 'gcash_out') {
        gcashReports.add(Map<String, dynamic>.from(tx));
        totalExpenses += (tx['amount'] ?? 0.0);
      } else if (tx['type'] == 'load') {
        loadWalletReports.add(Map<String, dynamic>.from(tx));
        totalIncome += (tx['customerPays'] ?? 0.0);
        totalExpenses += (tx['deducted'] ?? 0.0);
      } else if (tx['type'] == 'topup') {
        loadWalletReports.add(Map<String, dynamic>.from(tx));
        totalExpenses += (tx['amount'] ?? 0.0);
      }
    }

    setState(() {
      _gcashReports = gcashReports;
      _loadWalletReports = loadWalletReports;
      _allReports = allReports;
      _totalIncome = totalIncome;
      _totalExpenses = totalExpenses;
    });
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Income', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Text(
                      '₱${_totalIncome.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Expenses', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Text(
                      '₱${_totalExpenses.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Net Cash Flow: ₱${(_totalIncome - _totalExpenses).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: (_totalIncome - _totalExpenses) >= 0 ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList(String title, List<Map> reports) {
    if (reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'No $title reports found',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final tx = reports[index];
            String subtitle = '';
            String amountStr = '';
            Color amountColor = Colors.black;
            bool isIncome = false;
            String date = DateTime.parse(tx['date']).toString().substring(0, 16);

            if (tx['type'] == 'gcash_in') {
              subtitle = 'GCash Cash In';
              amountStr = '₱${(tx['amount'] ?? 0.0).toStringAsFixed(2)}';
              amountColor = Colors.green[700]!;
              isIncome = true;
            } else if (tx['type'] == 'gcash_out') {
              subtitle = 'GCash Cash Out';
              amountStr = '₱${(tx['amount'] ?? 0.0).toStringAsFixed(2)}';
              amountColor = Colors.red[700]!;
              isIncome = false;
            } else if (tx['type'] == 'gcash_topup') {
              subtitle = 'GCash Top-up';
              amountStr = '₱${(tx['amount'] ?? 0.0).toStringAsFixed(2)}';
              amountColor = Colors.green[700]!;
              isIncome = true;
            } else if (tx['type'] == 'load') {
              double customerPays = tx['customerPays'] ?? 0.0;
              double deducted = tx['deducted'] ?? 0.0;
              double profit = tx['profit'] ?? 0.0;
              subtitle = 'Load Sale - Deducted: ₱${deducted.toStringAsFixed(2)} | Profit: ₱${profit.toStringAsFixed(2)}';
              amountStr = '₱${customerPays.toStringAsFixed(2)}';
              amountColor = Colors.green[700]!;
              isIncome = true;
            } else if (tx['type'] == 'topup') {
              subtitle = 'Load Wallet Top-up';
              amountStr = '₱${(tx['amount'] ?? 0.0).toStringAsFixed(2)}';
              amountColor = Colors.red[700]!;
              isIncome = false;
            } else {
              subtitle = tx['type'] ?? '';
              amountStr = '₱${(tx['amount'] ?? 0.0).toStringAsFixed(2)}';
              amountColor = Colors.black;
            }

            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: CircleAvatar(
                  backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: amountColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  subtitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  'Date: $date',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                trailing: Text(
                  amountStr,
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6B48FF), Color(0xFFD1C4E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar Section
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reports',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadReports,
                      tooltip: 'Refresh Reports',
                    ),
                  ],
                ),
              ),
              // TabBar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.account_balance_wallet, color: Colors.teal[700]),
                      text: 'GCash',
                    ),
                    Tab(
                      icon: Icon(Icons.phone_android, color: Colors.teal[700]),
                      text: 'Load',
                    ),
                    Tab(
                      icon: Icon(Icons.summarize, color: Colors.teal[700]),
                      text: 'Overall',
                    ),
                  ],
                  labelColor: Colors.teal[700],
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.teal[700],
                  indicatorWeight: 3,
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: _buildReportList('GCash Reports', _gcashReports),
                    ),
                    SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: _buildReportList('Load Wallet Reports', _loadWalletReports),
                    ),
                    SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCard(),
                          _buildReportList('All Transactions', _allReports),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}