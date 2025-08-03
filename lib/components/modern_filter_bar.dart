import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';

class ModernTransactionFilterBar extends StatefulWidget {
  final List<String> filterTypes;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const ModernTransactionFilterBar({
    Key? key,
    required this.filterTypes,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.padding,
    this.height,
  }) : super(key: key);

  @override
  State<ModernTransactionFilterBar> createState() => _ModernTransactionFilterBarState();
}

class _ModernTransactionFilterBarState extends State<ModernTransactionFilterBar>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  IconData _getFilterIcon(String filter) {
    switch (filter.toLowerCase()) {
      case 'all':
        return Icons.grid_view_rounded;
      case 'gcash in':
        return Icons.arrow_upward_rounded;
      case 'gcash out':
        return Icons.arrow_downward_rounded;
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

  Color _getFilterColor(String filter) {
    switch (filter.toLowerCase()) {
      case 'all':
        return AppTheme.primaryColor;
      case 'gcash in':
        return AppTheme.errorColor;
      case 'gcash out':
        return AppTheme.successColor;
      case 'load sale':
        return const Color(0xFF8B5CF6); // Purple
      case 'gcash topup':
        return AppTheme.accentColor;
      case 'load topup':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 64, // Reduced height from 80 to 64
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 4), // Reduced vertical padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Adjusted padding
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4), // Reduced padding
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6), // Smaller radius
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: AppTheme.primaryColor,
                    size: 14, // Smaller icon
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
          const SizedBox(height: 4), // Reduced spacing
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12), // Adjusted padding
              itemCount: widget.filterTypes.length,
              itemBuilder: (context, index) {
                final filter = widget.filterTypes[index];
                final isSelected = filter == widget.selectedFilter;
                final color = _getFilterColor(filter);
                final icon = _getFilterIcon(filter);

                return AnimationUtils.slideInFromBottom(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8), // Reduced margin
                    child: ModernFilterChip(
                      label: filter,
                      icon: icon,
                      color: color,
                      isSelected: isSelected,
                      onTap: () => widget.onFilterChanged(filter),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ModernFilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const ModernFilterChip({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ModernFilterChip> createState() => _ModernFilterChipState();
}

class _ModernFilterChipState extends State<ModernFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? widget.color 
                : AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium), // Smaller radius
            border: Border.all(
              color: widget.isSelected 
                  ? widget.color
                  : widget.color.withOpacity(0.2),
              width: widget.isSelected ? 1.5 : 1, // Thinner border
            ),
            boxShadow: [
              if (widget.isSelected) ...[
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 10, // Reduced blur
                  offset: const Offset(0, 3), // Smaller offset
                ),
                BoxShadow(
                  color: widget.color.withOpacity(0.15),
                  blurRadius: 16, // Reduced blur
                  offset: const Offset(0, 6), // Smaller offset
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6, // Reduced blur
                  offset: const Offset(0, 1), // Smaller offset
                ),
              ],
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4), // Reduced padding
                decoration: BoxDecoration(
                  color: widget.isSelected 
                      ? Colors.white.withOpacity(0.2)
                      : widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6), // Smaller radius
                ),
                child: Icon(
                  widget.icon,
                  size: 14, // Smaller icon
                  color: widget.isSelected 
                      ? Colors.white
                      : widget.color,
                ),
              ),
              const SizedBox(width: 6), // Reduced spacing
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith( // Changed to bodySmall
                  fontWeight: FontWeight.w600,
                  color: widget.isSelected 
                      ? Colors.white
                      : widget.color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernFilterBadge extends StatelessWidget {
  final int count;
  final Color color;

  const ModernFilterBadge({
    Key? key,
    required this.count,
    this.color = AppTheme.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 4), // Reduced margin
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Reduced padding
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8), // Smaller radius
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 9, // Smaller font
        ),
      ),
    );
  }
}

class EnhancedFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const EnhancedFilterChip({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium), // Smaller radius
          border: Border.all(
            color: isSelected 
                ? color
                : color.withOpacity(0.2),
            width: isSelected ? 1.5 : 1, // Thinner border
          ),
          boxShadow: [
            if (isSelected) ...[
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12, // Reduced blur
                offset: const Offset(0, 4), // Smaller offset
              ),
            ] else ...[
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6, // Reduced blur
                offset: const Offset(0, 1), // Smaller offset
              ),
            ],
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4), // Reduced padding
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6), // Smaller radius
              ),
              child: Icon(
                icon,
                size: 14, // Smaller icon
                color: isSelected 
                    ? Colors.white
                    : color,
              ),
            ),
            const SizedBox(width: 6), // Reduced spacing
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith( // Changed to bodySmall
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? Colors.white
                    : color,
                letterSpacing: 0.2,
              ),
            ),
            if (count != null && count! > 0)
              ModernFilterBadge(
                count: count!,
                color: isSelected 
                    ? Colors.white.withOpacity(0.3)
                    : color.withOpacity(0.8),
              ),
          ],
        ),
      ),
    );
  }
}