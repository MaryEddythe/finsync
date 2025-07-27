import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class QuickActionsWidget extends StatelessWidget {
  final Function(String, double?) onQuickAction;
  final double gcashBalance;
  final double loadWalletBalance;

  const QuickActionsWidget({
    Key? key,
    required this.onQuickAction,
    required this.gcashBalance,
    required this.loadWalletBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.orange[700], size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildQuickActionCard(
                context,
                'GCash In',
                Icons.arrow_upward,
                Colors.blue,
                () => onQuickAction('gcash_in', null),
                enabled: true,
              ),
              _buildQuickActionCard(
                context,
                'GCash Out',
                Icons.arrow_downward,
                Colors.green,
                () => onQuickAction('gcash_out', null),
                enabled: true,
              ),
              _buildQuickActionCard(
                context,
                'GIGA50',
                Icons.phone_android,
                Colors.purple,
                () => onQuickAction('load', 53),
                enabled: loadWalletBalance >= 48.54,
              ),
              _buildQuickActionCard(
                context,
                'GIGA99',
                Icons.phone_android,
                Colors.purple,
                () => onQuickAction('load', 102),
                enabled: loadWalletBalance >= 96.12,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'Load ₱100',
                  Icons.phone_android,
                  Colors.purple,
                  () => onQuickAction('load', 103),
                  enabled: loadWalletBalance >= 97.09,
                  isWide: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'Custom Load',
                  Icons.add_circle_outline,
                  Colors.orange,
                  () => onQuickAction('load', null),
                  enabled: true,
                  isWide: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    {bool enabled = true, bool isWide = false}
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: enabled ? color.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? color.withOpacity(0.3) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: enabled ? color.withOpacity(0.2) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: enabled ? color : Colors.grey[500],
                  size: 18,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: enabled ? Colors.grey[800] : Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!enabled)
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: Colors.grey[500],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
