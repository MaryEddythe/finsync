import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Alias for backwards compatibility
typedef EnhancedTransactionFormWithPresets = EnhancedTransactionForm;

class EnhancedTransactionForm extends StatefulWidget {
  final VoidCallback onTransactionSaved;
  final double gcashBalance;
  final double loadWalletBalance;
  final Function(double) onBalanceUpdate;
  final String? initialTransactionType;
  final double? presetAmount;

  const EnhancedTransactionForm({
    Key? key,
    required this.onTransactionSaved,
    required this.gcashBalance,
    required this.loadWalletBalance,
    required this.onBalanceUpdate,
    this.initialTransactionType,
    this.presetAmount,
  }) : super(key: key);

  @override
  _EnhancedTransactionFormState createState() => _EnhancedTransactionFormState();
}

class _EnhancedTransactionFormState extends State<EnhancedTransactionForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _transactionType = 'gcash_in';
  final _amountController = TextEditingController();
  final _customerPaysController = TextEditingController();
  final _walletDeductedController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _showAmountSuggestions = false;
  bool _showLoadPresets = false;
  
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final double _mayaCommissionRate = 0.03;
  final double _fixedMarkup = 3.0;

  // Common GCash amounts
  final List<double> _gcashAmountSuggestions = [
    100, 200, 300, 500, 1000, 1500, 2000, 2500, 3000, 5000
  ];

  // Load presets with common telecom packages
  final List<Map<String, dynamic>> _loadPresets = [
    {'name': 'Load 15', 'customer': 18, 'deducted': 14.55},
    {'name': 'Load 20', 'customer': 23, 'deducted': 19.40},
    {'name': 'Load 30', 'customer': 33, 'deducted': 29.10},
    {'name': 'Load 50', 'customer': 53, 'deducted': 48.50},
    {'name': 'Load 75', 'customer': 78, 'deducted': 72.75},
    {'name': 'Load 99', 'customer': 102, 'deducted': 96.03},
    {'name': 'Load 100', 'customer': 103, 'deducted': 97.0},
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _customerPaysController.addListener(_autoCalculateWalletDeducted);

    // Initialize with presets if provided
    if (widget.initialTransactionType != null) {
      _transactionType = widget.initialTransactionType!;
    }

    if (widget.presetAmount != null) {
      if (_transactionType == 'load') {
        // Find matching preset and set values
        final preset = _loadPresets.firstWhere(
          (p) => p['customer'] == widget.presetAmount,
          orElse: () => {'customer': widget.presetAmount, 'deducted': (widget.presetAmount! - _fixedMarkup) / (1 + _mayaCommissionRate)},
        );
        _customerPaysController.text = preset['customer'].toString();
        _walletDeductedController.text = preset['deducted'].toString();
      } else {
        _amountController.text = widget.presetAmount!.toStringAsFixed(0);
      }
    }

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _amountController.dispose();
    _customerPaysController.dispose();
    _walletDeductedController.dispose();
    _notesController.dispose();
    _customerPaysController.removeListener(_autoCalculateWalletDeducted);
    super.dispose();
  }

  void _autoCalculateWalletDeducted() {
    if (_transactionType == 'load') {
      final customerPays = double.tryParse(_customerPaysController.text);
      if (customerPays != null && customerPays > 0) {
        final walletDeducted = (customerPays - _fixedMarkup) / (1 + _mayaCommissionRate);
        _walletDeductedController.text = walletDeducted.toStringAsFixed(2);
      }
    }
  }

  double _calculateGcashFee(double amount) {
    if (amount <= 100) return 5;
    if (amount <= 300) return 10;
    if (amount <= 500) return 15;
    if (amount <= 1000) return 25;
    if (amount <= 1500) return 30;
    if (amount <= 2000) return 40;
    if (amount <= 2500) return 50;
    if (amount <= 3000) return 60;
    if (amount <= 3500) return 70;
    if (amount <= 4000) return 80;
    if (amount <= 4500) return 90;
    if (amount <= 5000) return 100;
    if (amount <= 5500) return 110;
    if (amount <= 6000) return 120;
    if (amount <= 6500) return 130;
    if (amount <= 7000) return 140;
    return 0;
  }

  void _selectAmountSuggestion(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    setState(() {
      _showAmountSuggestions = false;
    });
    _scaleController.forward().then((_) => _scaleController.reverse());
  }

  void _selectLoadPreset(Map<String, dynamic> preset) {
    _customerPaysController.text = preset['customer'].toString();
    _walletDeductedController.text = preset['deducted'].toString();
    setState(() {
      _showLoadPresets = false;
    });
    _scaleController.forward().then((_) => _scaleController.reverse());
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final box = Hive.box('transactions');
      final now = DateTime.now();

      if (_transactionType == 'load') {
        final customerPays = double.parse(_customerPaysController.text);
        final walletDeducted = double.parse(_walletDeductedController.text);
        
        if (widget.loadWalletBalance < walletDeducted) {
          _showErrorDialog('Insufficient load wallet balance!');
          return;
        }

        final mayaCommission = walletDeducted * _mayaCommissionRate;
        final profit = customerPays - walletDeducted;

        await box.add({
          'type': 'load',
          'customerPays': customerPays,
          'deducted': walletDeducted,
          'commission': mayaCommission,
          'profit': profit,
          'date': now.toIso8601String(),
          'notes': _notesController.text.trim(),
        });

        widget.onBalanceUpdate(-walletDeducted);
        _showSuccessAnimation('Load transaction saved! Profit: ₱${profit.toStringAsFixed(2)}');
      } else {
        final amount = double.parse(_amountController.text);
        final fee = _calculateGcashFee(amount);

        if (_transactionType == 'gcash_in' && widget.gcashBalance < amount) {
          _showErrorDialog('Insufficient GCash balance for cash-in!');
          return;
        }

        await box.add({
          'type': _transactionType,
          'amount': amount,
          'serviceFee': fee,
          'totalAmount': amount + fee,
          'date': now.toIso8601String(),
          'notes': _notesController.text.trim(),
        });

        widget.onBalanceUpdate(_transactionType == 'gcash_in' ? -amount : amount);
        _showSuccessAnimation('Transaction saved! Fee: ₱${fee.toStringAsFixed(2)}');
      }

      _clearForm();
      widget.onTransactionSaved();
    } catch (e) {
      _showErrorDialog('Failed to save transaction: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _amountController.clear();
    _customerPaysController.clear();
    _walletDeductedController.clear();
    _notesController.clear();
    setState(() {
      _transactionType = 'gcash_in';
      _showAmountSuggestions = false;
      _showLoadPresets = false;
    });
  }

  void _showSuccessAnimation(String message) {
    _scaleController.forward().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(seconds: 3),
        ),
      );
      _scaleController.reverse();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            SizedBox(width: 12),
            Text('Error', style: TextStyle(color: Colors.red[700])),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Text(
            'New Transaction',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTransactionTypeSelector(),
            SizedBox(height: 24),
            if (_transactionType != 'load') ...[
              _buildAmountField(),
              if (_showAmountSuggestions) _buildAmountSuggestions(),
              SizedBox(height: 16),
              _buildFeePreview(),
            ] else ...[
              _buildLoadPresetSection(),
              SizedBox(height: 16),
              _buildLoadFields(),
              if (_showLoadPresets) _buildLoadPresets(),
              SizedBox(height: 16),
              _buildProfitPreview(),
            ],
            SizedBox(height: 16),
            _buildNotesField(),
            SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildTypeOption('gcash_in', 'GCash Cash In', Icons.arrow_upward, Colors.blue),
              Divider(height: 1, indent: 56),
              _buildTypeOption('gcash_out', 'GCash Cash Out', Icons.arrow_downward, Colors.orange),
              Divider(height: 1, indent: 56),
              _buildTypeOption('load', 'Load Sale', Icons.phone_android, Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(String value, String title, IconData icon, Color color) {
    final isSelected = _transactionType == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _transactionType = value;
            _showAmountSuggestions = false;
            _showLoadPresets = false;
          });
          _clearForm();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? color : Colors.grey[600],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.grey[800] : Colors.grey[600],
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Enter amount (₱)',
            prefixIcon: Icon(Icons.attach_money, color: Colors.green[700]),
            suffixIcon: IconButton(
              icon: Icon(Icons.keyboard_arrow_down),
              onPressed: () {
                setState(() {
                  _showAmountSuggestions = !_showAmountSuggestions;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[700]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter an amount';
            if (double.tryParse(value) == null) return 'Please enter a valid number';
            if (double.parse(value) <= 0) return 'Amount must be greater than 0';
            return null;
          },
          onChanged: (value) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildAmountSuggestions() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick amounts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _gcashAmountSuggestions.map((amount) {
              return GestureDetector(
                onTap: () => _selectAmountSuggestion(amount),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Text(
                    '₱${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeePreview() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final fee = amount > 0 ? _calculateGcashFee(amount) : 0.0;
    final total = amount + fee;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount:', style: TextStyle(color: Colors.grey[700])),
              Text('₱${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Service Fee:', style: TextStyle(color: Colors.grey[700])),
              Text('₱${fee.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.amber[800])),
            ],
          ),
          Divider(color: Colors.amber[300]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800])),
              Text('₱${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadPresetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Load Packages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showLoadPresets = !_showLoadPresets;
                });
              },
              icon: Icon(Icons.apps, size: 18),
              label: Text('Presets'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple[700],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadFields() {
    return Column(
      children: [
        TextFormField(
          controller: _customerPaysController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Customer Pays (₱)',
            hintText: 'e.g. 53 for GIGA50',
            prefixIcon: Icon(Icons.payments, color: Colors.purple[700]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple[700]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter customer payment';
            if (double.tryParse(value) == null) return 'Please enter a valid number';
            if (double.parse(value) <= 0) return 'Amount must be greater than 0';
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _walletDeductedController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Wallet Deducted (₱)',
            hintText: 'Auto-calculated, but editable',
            prefixIcon: Icon(Icons.remove_circle_outline, color: Colors.red[700]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple[700]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter wallet deduction';
            if (double.tryParse(value) == null) return 'Please enter a valid number';
            if (double.parse(value) <= 0) return 'Amount must be greater than 0';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoadPresets() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Common Load Packages',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.purple[800],
            ),
          ),
          SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _loadPresets.length,
            itemBuilder: (context, index) {
              final preset = _loadPresets[index];
              return GestureDetector(
                onTap: () => _selectLoadPreset(preset),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        preset['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                      Text(
                        '₱${preset['customer']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfitPreview() {
    final customerPays = double.tryParse(_customerPaysController.text) ?? 0.0;
    final walletDeducted = double.tryParse(_walletDeductedController.text) ?? 0.0;
    final profit = customerPays - walletDeducted;
    final commission = walletDeducted * _mayaCommissionRate;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Customer Pays:', style: TextStyle(color: Colors.grey[700])),
              Text('₱${customerPays.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wallet Deducted:', style: TextStyle(color: Colors.grey[700])),
              Text('-₱${walletDeducted.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red[700])),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commission:', style: TextStyle(color: Colors.grey[700])),
              Text('-₱${commission.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.orange[700])),
            ],
          ),
          Divider(color: Colors.green[300]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profit:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
              Text('₱${profit.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Add transaction notes...',
            prefixIcon: Icon(Icons.note_add, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[700]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearForm,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Clear', style: TextStyle(fontSize: 16)),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save Transaction',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
