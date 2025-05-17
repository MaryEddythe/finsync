import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GCashTab extends StatefulWidget {
  @override
  _GCashTabState createState() => _GCashTabState();
}

class _GCashTabState extends State<GCashTab> {
  final _controller = TextEditingController();
  double? _fee;

  void _calculateAndSave() {
    final amount = double.tryParse(_controller.text);
    if (amount != null) {
      final fee = amount * 0.02; // 2% service fee
      setState(() => _fee = fee);

      final box = Hive.box('transactions');
      box.add({
        'type': 'gcash',
        'amount': amount,
        'fee': fee,
        'date': DateTime.now().toIso8601String(),
      });

      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Enter amount'),
          ),
        ),
        ElevatedButton(
          onPressed: _calculateAndSave,
          child: Text('Calculate and Save'),
        ),
        if (_fee != null)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text("Service Fee: ₱${_fee!.toStringAsFixed(2)}"),
          ),
        Expanded(child: _buildTransactionList('gcash')),
      ],
    );
  }

  Widget _buildTransactionList(String type) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('transactions').listenable(),
      builder: (context, box, _) {
        final today = DateTime.now();
        final items = box.values.where((e) {
          final date = DateTime.parse(e['date']);
          return e['type'] == type &&
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).toList();

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];
            return ListTile(
              title: Text("₱${item['amount']} + ₱${item['fee']}"),
              subtitle: Text("Date: ${item['date']}"),
            );
          },
        );
      },
    );
  }
}
