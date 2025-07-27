import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LoadForm extends StatefulWidget {
  final VoidCallback onTransactionSaved;
  final double loadWalletBalance;

  const LoadForm({
    Key? key,
    required this.onTransactionSaved,
    required this.loadWalletBalance,
  }) : super(key: key);

  @override
  _LoadFormState createState() => _LoadFormState();
}

class _LoadFormState extends State<LoadForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _customerPaysController = TextEditingController();
  final _walletDeductedController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  final double _mayaCommissionRate = 0.02;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _loadPresets = [
    {'name': 'GIA50', 'customer': 53.0, 'deducted': 48.50, 'description': '1GB Data, 3 days'},
    {'name': 'LOAD 100', 'customer': 103.0, 'deducted': 97.0, 'description': 'Regular Load'},
    {'name': 'LOAD 20', 'customer': 23.0, 'deducted': 19.40, 'description': 'Regular Load'},
    {'name': 'LOAD 30', 'customer': 33.0, 'deducted': 29.100, 'description': 'Regular Load'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _customerPaysController.dispose();
    _walletDeductedController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _selectLoadPreset(Map<String, dynamic> preset) {
    setState(() {
      _customerPaysController.text = preset['customer'].toString();
      _walletDeductedController.text = preset['deducted'].toString();
    });
  }

  void _clearForm() {
    setState(() {
      _customerPaysController.clear();
      _walletDeductedController.clear();
      _notesController.clear();
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final box = Hive.box('transactions');
      final balancesBox = Hive.box('balances');
      final customerPays = double.parse(_customerPaysController.text);
      final deducted = double.parse(_walletDeductedController.text);
      final commission = deducted * _mayaCommissionRate;

      // Check if enough balance
      if (widget.loadWalletBalance < deducted) {
        _showError('Insufficient load wallet balance!');
        setState(() => _isLoading = false);
        return;
      }

      // Update load wallet balance
      final currentBalance = balancesBox.get('load', defaultValue: 0.0);
      await balancesBox.put('load', currentBalance - deducted);

      // Save transaction
      await box.add({
        'type': 'load',
        'customerPays': customerPays,
        'deducted': deducted,
        'profit': customerPays - deducted,
        'commission': commission,
        'notes': _notesController.text,
        'date': DateTime.now().toIso8601String(),
      });

      widget.onTransactionSaved();
      Navigator.pop(context);
      _showSuccess('Load sale completed! Profit: ₱${(customerPays - deducted).toStringAsFixed(2)}');
    } catch (e) {
      _showError('Failed to save transaction: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[700]!, Colors.purple[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.phone_android, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Load Transaction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance, color: Colors.purple[700], size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Load Wallet',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.purple[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₱${widget.loadWalletBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[900],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Load Packages',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _loadPresets.length,
          itemBuilder: (context, index) {
            final preset = _loadPresets[index];
            final canAfford = widget.loadWalletBalance >= preset['deducted'];

            return GestureDetector(
              onTap: canAfford ? () => _selectLoadPreset(preset) : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canAfford ? Colors.purple[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: canAfford ? Colors.purple[200]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      preset['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: canAfford ? Colors.purple[800] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₱${preset['customer'].toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canAfford ? Colors.purple[900] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset['description'],
                      style: TextStyle(
                        fontSize: 10,
                        color: canAfford ? Colors.purple[600] : Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!canAfford)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              'Insufficient balance',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAmountFields() {
    return Column(
      children: [
        TextFormField(
          controller: _customerPaysController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            final amount = double.tryParse(value);
            if (amount == null) return 'Please enter a valid number';
            if (amount <= 0) return 'Amount must be greater than 0';
            return null;
          },
          onChanged: (value) {
            if (value.isNotEmpty) {
              final customerPays = double.tryParse(value) ?? 0.0;
              _walletDeductedController.text = (customerPays / 1.03).toStringAsFixed(2);
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _walletDeductedController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            final amount = double.tryParse(value);
            if (amount == null) return 'Please enter a valid number';
            if (amount <= 0) return 'Amount must be greater than 0';
            if (amount > widget.loadWalletBalance) return 'Insufficient load wallet balance';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfitPreview() {
    final customerPays = double.tryParse(_customerPaysController.text) ?? 0.0;
    final walletDeducted = double.tryParse(_walletDeductedController.text) ?? 0.0;
    final profit = customerPays - walletDeducted;
    final commission = walletDeducted * _mayaCommissionRate;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Text('₱${customerPays.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wallet Deducted:', style: TextStyle(color: Colors.grey[700])),
              Text('-₱${walletDeducted.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red[700])),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commission (2%):', style: TextStyle(color: Colors.grey[700])),
              Text('-₱${commission.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.orange[700])),
            ],
          ),
          Divider(color: Colors.green[300]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Profit:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
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
        const SizedBox(height: 8),
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
              borderSide: BorderSide(color: Colors.purple[700]!, width: 2),
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Process Load',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceInfo(),
                        const SizedBox(height: 24),
                        _buildLoadPresets(),
                        const SizedBox(height: 24),
                        _buildAmountFields(),
                        const SizedBox(height: 16),
                        _buildProfitPreview(),
                        const SizedBox(height: 16),
                        _buildNotesField(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}