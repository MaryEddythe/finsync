import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WalletPage extends StatefulWidget {
  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double _gcashBalance = 0.0;
  double _loadWalletBalance = 0.0;
  double _totalRevenue = 0.0;
  double _totalProfit = 0.0;
  double _mayaCommissionRate = 0.03;
  double _fixedMarkup = 3.0;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    final balancesBox = Hive.box('balances');
    final transactionsBox = Hive.box('transactions');

    setState(() {
      _gcashBalance = balancesBox.get('gcash', defaultValue: 0.0);
      _loadWalletBalance = balancesBox.get('load', defaultValue: 0.0);
    });

    double revenue = 0.0;
    double profit = 0.0;

    for (var tx in transactionsBox.values) {
      if (tx['type'] == 'load') {
        double customerPays = tx['customerPays'] ?? 0.0;
        double deducted = tx['deducted'] ?? 0.0;
        double mayaCommission = deducted * _mayaCommissionRate;
        double userMarkup = _fixedMarkup;
        double txProfit = userMarkup + (deducted - mayaCommission);
        revenue += customerPays;
        profit += txProfit;
      } else if (tx['type'] == 'gcash_in') {
        revenue += tx['amount'] ?? 0.0;
      } else if (tx['type'] == 'gcash_out') {
        revenue -= tx['amount'] ?? 0.0;
      } else if (tx['type'] == 'topup') {
        // topup adds to load wallet balance, no direct revenue
      }
    }

    setState(() {
      _totalRevenue = revenue;
      _totalProfit = profit;
    });
  }

  Widget _buildBalanceCard(String title, double amount, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 24),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '₱${amount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard() {
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
              'Revenue & Profit Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Revenue', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Text(
                      '₱${_totalRevenue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _totalRevenue >= 0 ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Profit', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Text(
                      '₱${_totalProfit.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactionsBox = Hive.box('transactions');
    final transactions = transactionsBox.values.toList().reversed.toList();

    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions found',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        String type = tx['type'] ?? '';
        String title = '';
        String subtitle = '';
        Color amountColor = Colors.black;
        double amount = 0.0;
        bool isIncome = false;
        String date = tx['date'] != null ? tx['date'].toString().substring(0, 16) : 'No date';
        IconData icon;

        if (type == 'load') {
          title = 'Load Sale';
          double customerPays = tx['customerPays'] ?? 0.0;
          double deducted = tx['deducted'] ?? 0.0;
          double profit = _fixedMarkup + (deducted - (deducted * _mayaCommissionRate));
          subtitle = 'Paid: ₱${customerPays.toStringAsFixed(2)} | Deducted: ₱${deducted.toStringAsFixed(2)} | Profit: ₱${profit.toStringAsFixed(2)}';
          amount = customerPays;
          amountColor = Colors.green[700]!;
          isIncome = true;
          icon = Icons.phone_android;
        } else if (type == 'gcash_in') {
          title = 'GCash Cash In';
          amount = tx['amount'] ?? 0.0;
          subtitle = '';
          amountColor = Colors.green[700]!;
          isIncome = true;
          icon = Icons.account_balance_wallet;
        } else if (type == 'gcash_out') {
          title = 'GCash Cash Out';
          amount = tx['amount'] ?? 0.0;
          subtitle = '';
          amountColor = Colors.red[700]!;
          isIncome = false;
          icon = Icons.account_balance_wallet;
        } else if (type == 'topup') {
          title = 'Load Wallet Top-up';
          amount = tx['amount'] ?? 0.0;
          subtitle = '';
          amountColor = Colors.green[700]!;
          isIncome = true;
          icon = Icons.phone_android;
        } else {
          title = type;
          amount = tx['amount'] ?? 0.0;
          subtitle = '';
          amountColor = Colors.black;
          icon = Icons.help_outline;
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
                icon,
                color: amountColor,
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle.isNotEmpty) ...[
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  SizedBox(height: 4),
                ],
                Text('Date: $date', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            trailing: Text(
              '₱${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Wallet Details & Analytics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadWalletData,
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Wallet Balances
                Text(
                  'Wallet Balances',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildBalanceCard(
                      'GCash Balance',
                      _gcashBalance,
                      Colors.blue[700]!,
                      Icons.account_balance_wallet,
                    ),
                    _buildBalanceCard(
                      'Load Wallet Balance',
                      _loadWalletBalance,
                      Colors.green[700]!,
                      Icons.phone_android,
                    ),
                  ],
                ),
                SizedBox(height: 24),
                // Analytics
                _buildAnalyticsCard(),
                SizedBox(height: 24),
                // Transaction History
                Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 12),
                _buildTransactionList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}