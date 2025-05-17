import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LoadTab extends StatefulWidget {
  @override
  _LoadTabState createState() => _LoadTabState();
}

class _LoadTabState extends State<LoadTab> {
  final _customerPaysController = TextEditingController();
  final _walletDeductedController = TextEditingController();

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

      _customerPaysController.clear();
      _walletDeductedController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _customerPaysController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Customer Pays'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _walletDeductedController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Wallet Deducted'),
          ),
        ),
        ElevatedButton(
          onPressed: _saveLoadTransaction,
          child: Text('Save Load Transaction'),
        ),
        Expanded(child: _buildTransactionList()),
      ],
    );
  }

  Widget _buildTransactionList() {
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
        }).toList();

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];
            return ListTile(
              title: Text("₱${item['customerPays']} - ₱${item['deducted']}"),
              subtitle: Text("Profit: ₱${item['profit'].toStringAsFixed(2)}"),
            );
          },
        );
      },
    );
  }
}
