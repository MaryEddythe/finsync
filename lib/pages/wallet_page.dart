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

  Widget _buildBalanceCard(String title, double amount, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            SizedBox(height: 8),
            Text('₱${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactionsBox = Hive.box('transactions');
    final transactions = transactionsBox.values.toList().reversed.toList();

    if (transactions.isEmpty) {
      return Center(child: Text('No transactions found', style: TextStyle(color: Colors.grey)));
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
        String date = tx['date'] != null ? tx['date'].toString().substring(0, 10) : 'No date';

        if (type == 'load') {
          title = 'Load Sale';
          double customerPays = tx['customerPays'] ?? 0.0;
          double deducted = tx['deducted'] ?? 0.0;
          double profit = _fixedMarkup + (deducted - (deducted * _mayaCommissionRate));
          subtitle = 'Paid: ₱${customerPays.toStringAsFixed(2)} | Deducted: ₱${deducted.toStringAsFixed(2)} | Profit: ₱${profit.toStringAsFixed(2)} | Date: $date';
          amount = customerPays;
          amountColor = Colors.green;
        } else if (type == 'gcash_in') {
          title = 'GCash Cash In';
          amount = tx['amount'] ?? 0.0;
          subtitle = 'Date: $date';
          amountColor = Colors.green;
        } else if (type == 'gcash_out') {
          title = 'GCash Cash Out';
          amount = tx['amount'] ?? 0.0;
          subtitle = 'Date: $date';
          amountColor = Colors.red;
        } else if (type == 'topup') {
          title = 'Load Wallet Top-up';
          amount = tx['amount'] ?? 0.0;
          subtitle = 'Date: $date';
          amountColor = Colors.green;
        } else {
          title = type;
          amount = tx['amount'] ?? 0.0;
          subtitle = 'Date: $date';
        }

        return ListTile(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(fontSize: 12)) : null,
          trailing: Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallet Details & Analytics'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wallet Balances', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Row(
              children: [
                _buildBalanceCard('GCash Balance', _gcashBalance, Colors.blue),
                _buildBalanceCard('Load Wallet Balance', _loadWalletBalance, Colors.green),
              ],
            ),
            SizedBox(height: 24),
            Text('Revenue & Profit Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Revenue:', style: TextStyle(fontSize: 16)),
                      Text('₱${_totalRevenue.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Profit (Markup + Commission):', style: TextStyle(fontSize: 16)),
                      Text('₱${_totalProfit.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text('Transaction History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }
}
