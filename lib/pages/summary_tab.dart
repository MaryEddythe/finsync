import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SummaryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('transactions').listenable(),
      builder: (context, box, _) {
        final today = DateTime.now();
        final items = box.values.where((e) {
          final date = DateTime.parse(e['date']);
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        });

        double gcashProfit = 0;
        double loadProfit = 0;

        for (var item in items) {
          if (item['type'] == 'gcash') gcashProfit += item['fee'];
          if (item['type'] == 'load') loadProfit += item['profit'];
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Daily Summary", style: TextStyle(fontSize: 20)),
              SizedBox(height: 20),
              Text("GCash Profit: ₱${gcashProfit.toStringAsFixed(2)}"),
              Text("Load Profit: ₱${loadProfit.toStringAsFixed(2)}"),
              Divider(),
              Text("Total Profit: ₱${(gcashProfit + loadProfit).toStringAsFixed(2)}"),
            ],
          ),
        );
      },
    );
  }
}
