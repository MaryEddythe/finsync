import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<Map> _gcashReports = [];
  List<Map> _loadWalletReports = [];

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

    for (var tx in allTransactions) {
      if (tx['type'] == 'gcash_in' || tx['type'] == 'gcash_out') {
        gcashReports.add(Map<String, dynamic>.from(tx));
      } else if (tx['type'] == 'load' || tx['type'] == 'topup') {
        loadWalletReports.add(Map<String, dynamic>.from(tx));
      }
    }

    setState(() {
      _gcashReports = gcashReports;
      _loadWalletReports = loadWalletReports;
    });
  }

  Widget _buildReportList(String title, List<Map> reports) {
    if (reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('No $title reports found', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

            if (tx['type'] == 'gcash_in') {
              subtitle = 'GCash Cash In';
              amountStr = '₱${(tx['amount'] ?? 0.0).toStringAsFixed(2)}';
              amountColor = Colors.green;
            } else if (tx['type'] == 'gcash_out') {
              subtitle = 'GCash Cash Out';
              amountStr = '₱${(tx['amount'] ?? 0.0).toStringAsFixed(2)}';
              amountColor = Colors.red;
            } else if (tx['type'] == 'load') {
              double customerPays = tx['customerPays'] ?? 0.0;
              double deducted = tx['deducted'] ?? 0.0;
              double profit = tx['profit'] ?? 0.0;
              subtitle = 'Load Sale - Deducted: ₱${deducted.toStringAsFixed(2)} | Profit: ₱${profit.toStringAsFixed(2)}';
              amountStr = '₱${customerPays.toStringAsFixed(2)}';
              amountColor = Colors.green;
            } else if (tx['type'] == 'topup') {
              subtitle = 'Load Wallet Top-up';
              amountStr = '₱${(tx['amount'] ?? 0.0).toStringAsFixed(2)}';
              amountColor = Colors.green;
            } else {
              subtitle = tx['type'] ?? '';
              amountStr = '₱${(tx['amount'] ?? 0.0).toStringAsFixed(2)}';
            }

            return ListTile(
              title: Text(subtitle, style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(
                amountStr,
                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
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
      appBar: AppBar(
        title: Text('Reports - GCash and Load Wallet'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportList('GCash', _gcashReports),
            _buildReportList('Load Wallet', _loadWalletReports),
          ],
        ),
      ),
    );
  }
}
