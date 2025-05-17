import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6B48FF), Color(0xFFD1C4E9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Removed Profile Section (replaced with simple spacing)
                SizedBox(height: 16),
                // TabBar
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    tabs: [
                      Tab(
                        icon: Icon(Icons.account_balance_wallet, color: Colors.green[700]),
                        text: 'GCash',
                      ),
                      Tab(
                        icon: Icon(Icons.phone_android, color: Colors.green[700]),
                        text: 'Load',
                      ),
                    ],
                    labelColor: Colors.green[700],
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.green[700],
                    indicatorWeight: 3,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TransactionHistoryTab(type: 'gcash'),
                      _TransactionHistoryTab(type: 'load'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionHistoryTab extends StatelessWidget {
  final String type;
  const _TransactionHistoryTab({required this.type});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('transactions').listenable(),
      builder: (context, box, _) {
        final items = box.values.where((e) => e['type'] == type).toList().reversed.toList();
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No $type transactions yet.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isIncome = item['type'] == 'gcash_in' || item['type'] == 'gcash_topup';
            final amount = item['amount'] ?? (item['customerPays'] ?? 0.0);
            final deducted = item['deducted'] ?? 0.0;
            final profit = item['profit'] ?? 0.0;
            final date = DateTime.parse(item['date']).toString().substring(0, 16);
            final status = 'Confirmed'; // Assume all transactions are confirmed for now

            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: CircleAvatar(
                  backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.green[700] : Colors.red[700],
                    size: 20,
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type == 'gcash'
                          ? (isIncome ? 'Cash In' : 'Cash Out')
                          : 'Load Sale',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '₱${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isIncome ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (type == 'load') ...[
                      Text('Deducted: ₱${deducted.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                      Text('Profit: ₱${profit.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                    ],
                    SizedBox(height: 4),
                    Text('Date: $date', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: Colors.green[700], fontSize: 12),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}