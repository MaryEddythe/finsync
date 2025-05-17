import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RefillTab extends StatefulWidget {
  @override
  _RefillTabState createState() => _RefillTabState();
}

class _RefillTabState extends State<RefillTab> {
  final _amountController = TextEditingController();

  void _saveRefill() {
    final amount = double.tryParse(_amountController.text);
    if (amount != null) {
      Hive.box('transactions').add({
        'type': 'refill',
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
      });
      _amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Refill Amount'),
          ),
        ),
        ElevatedButton(
          onPressed: _saveRefill,
          child: Text('Save Refill'),
        ),
        Expanded(child: _buildRefillList()),
      ],
    );
  }

  Widget _buildRefillList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('transactions').listenable(),
      builder: (context, box, _) {
        final today = DateTime.now();
        final items = box.values.where((e) {
          final date = DateTime.parse(e['date']);
          return e['type'] == 'refill' &&
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).toList();

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];
            return ListTile(
              title: Text("Refill: ₱${item['amount']}"),
              subtitle: Text("Date: ${item['date']}"),
            );
          },
        );
      },
    );
  }
}
