import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Transaction History'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'GCash'),
              Tab(text: 'Load'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TransactionHistoryTab(type: 'gcash'),
            _TransactionHistoryTab(type: 'load'),
          ],
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
          return Center(child: Text('No $type transactions yet.'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];
            return ListTile(
              title: Text("₱${item['customerPays']} - ₱${item['deducted']}"),
              subtitle: Text(
                "Profit: ₱${item['profit'].toStringAsFixed(2)}\nDate: ${item['date']}",
              ),
            );
          },
        );
      },
    );
  }
}
