import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textTertiary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.home_rounded,
                isSelected: false,
              ),
              activeIcon: _NavIcon(
                icon: Icons.home_rounded,
                isSelected: true,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.calculate_rounded,
                isSelected: false,
              ),
              activeIcon: _NavIcon(
                icon: Icons.calculate_rounded,
                isSelected: true,
              ),
              label: 'Calc',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.account_balance_wallet_rounded,
                isSelected: false,
              ),
              activeIcon: _NavIcon(
                icon: Icons.account_balance_wallet_rounded,
                isSelected: true,
              ),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.history_rounded,
                isSelected: false,
              ),
              activeIcon: _NavIcon(
                icon: Icons.history_rounded,
                isSelected: true,
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.bar_chart_rounded,
                isSelected: false,
              ),
              activeIcon: _NavIcon(
                icon: Icons.bar_chart_rounded,
                isSelected: true,
              ),
              label: 'Report',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const _NavIcon({
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Icon(
        icon,
        size: 24,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
      ),
    );
  }
}
