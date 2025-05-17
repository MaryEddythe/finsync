import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  String _transactionType = 'gcash_in';
  final _amountController = TextEditingController();

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount != null) {
        final box = Hive.box('transactions');
        box.add({
          'type': _transactionType,
          'amount': amount,
          'date': DateTime.now().toIso8601String(),
        });
        _amountController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction saved!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('transactions')) {
      return Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _transactionType,
              items: [
                DropdownMenuItem(value: 'gcash_in', child: Text('GCash Cash In')),
                DropdownMenuItem(value: 'gcash_out', child: Text('GCash Cash Out')),
                DropdownMenuItem(value: 'load_sold', child: Text('Load Sold')),
                DropdownMenuItem(value: 'topup', child: Text('Top-up')),
              ],
              onChanged: (val) {
                setState(() {
                  _transactionType = val!;
                });
              },
              decoration: InputDecoration(labelText: 'Transaction Type'),
            ),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter amount';
                if (double.tryParse(value) == null) return 'Enter valid number';
                return null;
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: Text('Log Transaction'),
            ),
            SizedBox(height: 24),
            Expanded(child: _buildTodayTransactionList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTransactionList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('transactions').listenable(),
      builder: (context, box, _) {
        final today = DateTime.now();
        final items = box.values.where((e) {
          final date = DateTime.parse(e['date']);
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).toList().reversed.toList();

        if (items.isEmpty) {
          return Center(child: Text('No transactions logged today.'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];
            String typeLabel;
            switch (item['type']) {
              case 'gcash_in':
                typeLabel = 'GCash Cash In';
                break;
              case 'gcash_out':
                typeLabel = 'GCash Cash Out';
                break;
              case 'load_sold':
                typeLabel = 'Load Sold';
                break;
              case 'topup':
                typeLabel = 'Top-up';
                break;
              default:
                typeLabel = item['type'];
            }
            return ListTile(
              title: Text("$typeLabel: ₱${item['amount']}"),
              subtitle: Text("Date: ${item['date']}"),
            );
          },
        );
      },
    );
  }
}
