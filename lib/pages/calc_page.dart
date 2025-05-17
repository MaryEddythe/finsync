import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalcPage extends StatefulWidget {
  @override
  _CalcPageState createState() => _CalcPageState();
}

class _CalcPageState extends State<CalcPage> {
  final TextEditingController _amountController = TextEditingController();
  double _serviceFee = 0.0;
  double _totalAmount = 0.0;
  bool _showFeeTable = false;

  void _calculateFee() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    if (amount <= 0) {
      setState(() {
        _serviceFee = 0.0;
        _totalAmount = 0.0;
      });
      return;
    }

    double fee;
    if (amount <= 100) {
      fee = 5;
    } else if (amount <= 300) {
      fee = 10;
    } else if (amount <= 500) {
      fee = 15;
    } else if (amount <= 1000) {
      fee = 25;
    } else if (amount <= 1500) {
      fee = 35;
    } else if (amount <= 2000) {
      fee = 45;
    } else if (amount <= 2500) {
      fee = 50;
    } else if (amount <= 3000) {
      fee = 60;
    } else if (amount <= 3500) {
      fee = 70;
    } else if (amount <= 4000) {
      fee = 80;
    } else if (amount <= 4500) {
      fee = 90;
    } else if (amount <= 5000) {
      fee = 100;
    } else if (amount <= 5500) {
      fee = 110;
    } else if (amount <= 6000) {
      fee = 120;
    } else if (amount <= 6500) {
      fee = 130;
    } else if (amount <= 7000) {
      fee = 140;
    } else {
      fee = 0; // For amounts above ₱7,000
    }

    setState(() {
      _serviceFee = fee;
      _totalAmount = amount + fee;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text('GCash Load Calculator', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About'),
                  content: Text('This calculator helps you determine the service fees for cashing in to your GCash wallet.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Enter Cash-In Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: onSurface.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        prefixText: '₱',
                        prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode ? surfaceColor.withOpacity(0.5) : Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        hintText: '0.00',
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                        suffixIcon: _amountController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _amountController.clear();
                                  _calculateFee();
                                },
                              )
                            : null,
                      ),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.end,
                      onChanged: (value) => _calculateFee(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Results Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAmountRow('Cash-In Amount:', _amountController.text.isEmpty ? 0.0 : double.tryParse(_amountController.text) ?? 0.0),
                    Divider(height: 24, thickness: 0.5),
                    _buildAmountRow('Service Fee:', _serviceFee, isFee: true),
                    Divider(height: 24, thickness: 0.5),
                    _buildAmountRow('Total Amount:', _totalAmount, isTotal: true),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Fee Table Toggle
            OutlinedButton.icon(
              icon: Icon(_showFeeTable ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              label: Text(_showFeeTable ? 'Hide Fee Table' : 'Show Fee Table'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  _showFeeTable = !_showFeeTable;
                });
              },
            ),
            SizedBox(height: 12),

            // Fee Table
            if (_showFeeTable) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash-In Fee Chart',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Service fees for cashing in to GCash',
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 40,
                              dataRowHeight: 36,
                              columnSpacing: 24,
                              horizontalMargin: 16,
                              columns: [
                                DataColumn(
                                  label: Text(
                                    'Cash-In Amount (₱)',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Service Fee (₱)',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                              rows: _buildFeeTableRows(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isFee = false, bool isTotal = false}) {
    final theme = Theme.of(context);
    final amountColor = isTotal ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: theme.colorScheme.onSurface.withOpacity(isTotal ? 0.9 : 0.7),
          ),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isFee ? Colors.red : amountColor,
          ),
        ),
      ],
    );
  }

  List<DataRow> _buildFeeTableRows() {
    return [
      _buildFeeTableRow('1 - 100', '5'),
      _buildFeeTableRow('201 - 300', '10'),
      _buildFeeTableRow('301 - 500', '15'),
      _buildFeeTableRow('501 - 1,000', '25'),
      _buildFeeTableRow('1,001 - 1,500', '35'),
      _buildFeeTableRow('1,501 - 2,000', '45'),
      _buildFeeTableRow('2,001 - 2,500', '50'),
      _buildFeeTableRow('2,501 - 3,000', '60'),
      _buildFeeTableRow('3,001 - 3,500', '70'),
      _buildFeeTableRow('3,501 - 4,000', '80'),
      _buildFeeTableRow('4,001 - 4,500', '90'),
      _buildFeeTableRow('4,501 - 5,000', '100'),
      _buildFeeTableRow('5,001 - 5,500', '110'),
      _buildFeeTableRow('5,501 - 6,000', '120'),
      _buildFeeTableRow('6,001 - 6,500', '130'),
      _buildFeeTableRow('6,501 - 7,000', '140'),
    ];
  }

  DataRow _buildFeeTableRow(String range, String fee) {
    final isCurrentRange = _isInCurrentRange(range);
    final theme = Theme.of(context);

    return DataRow(
      cells: [
        DataCell(
          Text(
            range,
            style: TextStyle(
              fontWeight: isCurrentRange ? FontWeight.bold : FontWeight.normal,
              color: isCurrentRange ? theme.colorScheme.primary : null,
            ),
          ),
        ),
        DataCell(
          Text(
            fee,
            style: TextStyle(
              fontWeight: isCurrentRange ? FontWeight.bold : FontWeight.normal,
              color: isCurrentRange ? theme.colorScheme.primary : null,
            ),
          ),
        ),
      ],
    );
  }

  bool _isInCurrentRange(String range) {
    if (_amountController.text.isEmpty) return false;
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return false;

    final rangeParts = range.split(' - ');
    if (rangeParts.length != 2) return false;

    final min = double.tryParse(rangeParts[0].replaceAll(',', '')) ?? 0.0;
    final max = double.tryParse(rangeParts[1].replaceAll(',', '')) ?? 0.0;

    return amount >= min && amount <= max;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}