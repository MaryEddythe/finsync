import 'package:flutter/material.dart';
import 'gcash_in_form.dart';
import 'gcash_out_form.dart';
import 'load_form.dart';
import '../theme/app_theme.dart';
import '../components/modern_card.dart';
import '../components/modern_buttons.dart';

class TransactionButtons extends StatelessWidget {
  final VoidCallback onTransactionSaved;
  final double gcashBalance;
  final double loadWalletBalance;

  const TransactionButtons({
    Key? key,
    required this.onTransactionSaved,
    required this.gcashBalance,
    required this.loadWalletBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lightning fast transactions at your fingertips',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 14),
          // Three main transaction buttons
          Row(
            children: [
              Expanded(
                child: _buildTransactionButton(
                  context,
                  title: 'Cash In',
                  icon: Icons.arrow_upward,
                  color: Colors.blue,
                  gradient: [Colors.blue[700]!, Colors.blue[500]!],
                  onTap: () => _showGCashInForm(context),
                  balance: null,
                  balanceLabel: 'GCash',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTransactionButton(
                  context,
                  title: 'Cash Out',
                  icon: Icons.arrow_downward,
                  color: Colors.green,
                  gradient: [Colors.green[700]!, Colors.green[500]!],
                  onTap: () => _showGCashOutForm(context),
                  balance: null, // No balance check for cash out
                  balanceLabel: '',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTransactionButton(
                  context,
                  title: 'Sale',
                  icon: Icons.phone_android,
                  color: Colors.purple,
                  gradient: [Colors.purple[700]!, Colors.purple[500]!],
                  onTap: () => _showLoadForm(context),
                  balance: null,
                  balanceLabel: 'Load Wallet',
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildQuickLoadButton(
                  context,
                  name: 'Load 50',
                  price: '₱53',
                  customer: 53.0,
                  deducted: 47.0, // 53 - 6 profit
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildQuickLoadButton(
                  context,
                  name: 'Load 99',
                  price: '₱102',
                  customer: 102.0,
                  deducted: 96.0, // 102 - 6 profit
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildQuickLoadButton(
                  context,
                  name: 'Load 100',
                  price: '₱103',
                  customer: 103.0,
                  deducted: 97.0, // 103 - 6 profit
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    required VoidCallback onTap,
    required double? balance,
    required String balanceLabel,
  }) {
    return ActionButton(
      title: title,
      icon: icon,
      gradient: LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      subtitle: balance != null ? '₱${balance.toStringAsFixed(0)}' : null,
      onTap: onTap,
    );
  }

  Widget _buildQuickLoadButton(
    BuildContext context, {
    required String name,
    required String price,
    required double customer,
    required double deducted,
  }) {
    final canAfford = loadWalletBalance >= deducted;

    return QuickActionChip(
      title: name,
      subtitle: price,
      color: AppTheme.primaryColor,
      isEnabled: canAfford,
      onTap: canAfford ? () => _showLoadFormWithPreset(context, customer, deducted) : null,
    );
  }

  void _showGCashInForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => GCashInForm(
          onTransactionSaved: onTransactionSaved,
          gcashBalance: gcashBalance,
        ),
      ),
    );
  }

  void _showGCashOutForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => GCashOutForm(
          onTransactionSaved: onTransactionSaved,
        ),
      ),
    );
  }

  void _showLoadForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => LoadForm(
          onTransactionSaved: onTransactionSaved,
          loadWalletBalance: loadWalletBalance,
        ),
      ),
    );
  }

  void _showLoadFormWithPreset(BuildContext context, double customer, double deducted) {
    // Show regular load form - user can select the preset from within the form
    _showLoadForm(context);
  }
}
