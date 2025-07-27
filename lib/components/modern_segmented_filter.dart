import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';

class ModernSegmentedFilter extends StatefulWidget {
  final List<String> options;
  final String selectedOption;
  final Function(String) onChanged;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final bool showIcons;

  const ModernSegmentedFilter({
    Key? key,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
    this.padding,
    this.height,
    this.showIcons = true,
  }) : super(key: key);

  @override
  State<ModernSegmentedFilter> createState() => _ModernSegmentedFilterState();
}

class _ModernSegmentedFilterState extends State<ModernSegmentedFilter>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.options.indexOf(widget.selectedOption);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void didUpdateWidget(ModernSegmentedFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.options.indexOf(widget.selectedOption);
    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
      _slideController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  IconData _getOptionIcon(String option) {
    switch (option.toLowerCase()) {
      case 'all':
        return Icons.apps_rounded;
      case 'gcash in':
        return Icons.north_east_rounded;
      case 'gcash out':
        return Icons.south_east_rounded;
      case 'load sale':
        return Icons.smartphone_rounded;
      case 'gcash topup':
        return Icons.account_balance_wallet_rounded;
      case 'load topup':
        return Icons.add_box_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getOptionColor(String option) {
    switch (option.toLowerCase()) {
      case 'all':
        return AppTheme.primaryColor;
      case 'gcash in':
        return const Color(0xFFEF4444); // Red
      case 'gcash out':
        return const Color(0xFF10B981); // Green
      case 'load sale':
        return const Color(0xFF8B5CF6); // Purple
      case 'gcash topup':
        return const Color(0xFF06B6D4); // Cyan
      case 'load topup':
        return const Color(0xFFF59E0B); // Amber
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 120,
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimationUtils.slideInFromLeft(
            duration: const Duration(milliseconds: 500),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Transaction Filters',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.options.length} filters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimationUtils.slideInFromBottom(
              duration: const Duration(milliseconds: 600),
              child: _buildSegmentedControl(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: widget.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = index == _selectedIndex;
          final color = _getOptionColor(option);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (index != _selectedIndex) {
                  widget.onChanged(option);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.showIcons) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.2)
                              : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getOptionIcon(option),
                          color: isSelected ? Colors.white : color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      _getShortLabel(option),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : color,
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getShortLabel(String option) {
    switch (option.toLowerCase()) {
      case 'gcash in':
        return 'Cash In';
      case 'gcash out':
        return 'Cash Out';
      case 'load sale':
        return 'Load';
      case 'gcash topup':
        return 'GCash+';
      case 'load topup':
        return 'Load+';
      default:
        return option;
    }
  }
}

// Alternative floating filter bar design
class FloatingFilterBar extends StatelessWidget {
  final List<String> options;
  final String selectedOption;
  final Function(String) onChanged;

  const FloatingFilterBar({
    Key? key,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: options.map((option) {
            final isSelected = option == selectedOption;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFloatingChip(option, isSelected),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFloatingChip(String option, bool isSelected) {
    final color = _getOptionColor(option);
    
    return GestureDetector(
      onTap: () => onChanged(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getOptionIcon(option),
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              option,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getOptionIcon(String option) {
    switch (option.toLowerCase()) {
      case 'all':
        return Icons.apps_rounded;
      case 'gcash in':
        return Icons.north_east_rounded;
      case 'gcash out':
        return Icons.south_east_rounded;
      case 'load sale':
        return Icons.smartphone_rounded;
      case 'gcash topup':
        return Icons.account_balance_wallet_rounded;
      case 'load topup':
        return Icons.add_box_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getOptionColor(String option) {
    switch (option.toLowerCase()) {
      case 'all':
        return AppTheme.primaryColor;
      case 'gcash in':
        return const Color(0xFFEF4444);
      case 'gcash out':
        return const Color(0xFF10B981);
      case 'load sale':
        return const Color(0xFF8B5CF6);
      case 'gcash topup':
        return const Color(0xFF06B6D4);
      case 'load topup':
        return const Color(0xFFF59E0B);
      default:
        return AppTheme.textSecondary;
    }
  }
}

// Pill-style filter navigation
class PillFilterNavigation extends StatelessWidget {
  final List<String> options;
  final String selectedOption;
  final Function(String) onChanged;

  const PillFilterNavigation({
    Key? key,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selectedOption;
          final color = _getOptionColor(option);
          
          return AnimationUtils.scaleIn(
            duration: Duration(milliseconds: 300 + (index * 100)),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: _buildPillChip(option, isSelected, color),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPillChip(String option, bool isSelected, Color color) {
    return GestureDetector(
      onTap: () => onChanged(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: isSelected ? null : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getOptionIcon(option),
                size: 14,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getDisplayName(option),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayName(String option) {
    switch (option.toLowerCase()) {
      case 'gcash in':
        return 'Cash In';
      case 'gcash out':
        return 'Cash Out';
      case 'load sale':
        return 'Load Sale';
      case 'gcash topup':
        return 'GCash Top-up';
      case 'load topup':
        return 'Load Top-up';
      default:
        return option;
    }
  }

  IconData _getOptionIcon(String option) {
    switch (option.toLowerCase()) {
      case 'all':
        return Icons.dashboard_rounded;
      case 'gcash in':
        return Icons.trending_up_rounded;
      case 'gcash out':
        return Icons.trending_down_rounded;
      case 'load sale':
        return Icons.phone_android_rounded;
      case 'gcash topup':
        return Icons.account_balance_wallet_rounded;
      case 'load topup':
        return Icons.add_circle_outline_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getOptionColor(String option) {
    switch (option.toLowerCase()) {
      case 'all':
        return AppTheme.primaryColor;
      case 'gcash in':
        return const Color(0xFFEF4444);
      case 'gcash out':
        return const Color(0xFF10B981);
      case 'load sale':
        return const Color(0xFF8B5CF6);
      case 'gcash topup':
        return const Color(0xFF06B6D4);
      case 'load topup':
        return const Color(0xFFF59E0B);
      default:
        return AppTheme.textSecondary;
    }
  }
}
