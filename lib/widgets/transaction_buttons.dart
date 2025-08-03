import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'gcash_in_form.dart';
import 'gcash_out_form.dart';
import 'load_form.dart';
import '../theme/app_theme.dart';
import '../components/modern_card.dart';

class ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final VoidCallback? onTap;

  const ActionButton({
    Key? key,
    required this.title,
    required this.icon,
    required this.gradient,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: titleStyle ??
                  Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: subtitleStyle ??
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class QuickActionChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final bool isEnabled;
  final VoidCallback? onTap;

  const QuickActionChip({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isEnabled,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isEnabled ? color : Colors.grey,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isEnabled ? color : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isEnabled ? color.withOpacity(0.7) : Colors.grey.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          const SizedBox(height: 14),
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
                  isCashOut: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTransactionButton(
                  context,
                  title: 'Cash Out',
                  icon: Icons.arrow_downward,
                  color: Colors.green,
                  gradient: [Colors.green[700]!, Colors.green[500]!],
                  onTap: () => _showGCashOutForm(context),
                  balance: null,
                  balanceLabel: '',
                  isCashOut: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTransactionButton(
                  context,
                  title: 'Load',
                  icon: Icons.phone_android,
                  color: Colors.purple,
                  gradient: [Colors.purple[700]!, Colors.purple[500]!],
                  onTap: () => _showLoadForm(context),
                  balance: null,
                  balanceLabel: 'Load Wallet',
                  isCashOut: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildQuickLoadButton(
                  context,
                  name: 'Load 50',
                  price: '₱53',
                  customer: 53.0,
                  deducted: 47.0, 
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickLoadButton(
                  context,
                  name: 'Load 15',
                  price: '₱18',
                  customer: 18.0,
                  deducted: 14.55, // 18 - 3.45 profit
                ),
              ),
              const SizedBox(width: 8),
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
    required bool isCashOut,
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
      subtitleStyle: balanceLabel.isNotEmpty
          ? Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              )
          : null,
      onTap: onTap,
      titleStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: isCashOut ? 12 : 14,
          ),
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
      onTap: canAfford ? () => _showLoadFormWithPreset(context, name, customer, deducted) : null,
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

  void _showLoadFormWithPreset(BuildContext context, String name, double customer, double deducted) {
    if (loadWalletBalance < deducted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Insufficient load wallet balance!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }

    const mayaCommissionRate = 0.03;
    const fixedMarkup = 3.0;
    final commission = customer * mayaCommissionRate;
    final profit = customer - deducted - commission;

    final transactionBox = Hive.box('transactions');
    final balanceBox = Hive.box('balances');

    // Add transaction to Hive
    transactionBox.add({
      'type': 'load',
      'customerPays': customer,
      'deducted': deducted,
      'commission': commission,
      'profit': profit,
      'date': DateTime.now().toIso8601String(),
      'wallet': 'load',
    });

    // Update load wallet balance
    final currentLoadBalance = balanceBox.get('load', defaultValue: 0.0) as double;
    balanceBox.put('load', currentLoadBalance - deducted);

    // Update income and revenue in balances
    final currentIncome = balanceBox.get('income', defaultValue: 0.0) as double;
    final currentRevenue = balanceBox.get('revenue', defaultValue: 0.0) as double;
    balanceBox.put('income', currentIncome + customer);
    balanceBox.put('revenue', currentRevenue + profit);

    onTransactionSaved();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name transaction completed successfully!'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}