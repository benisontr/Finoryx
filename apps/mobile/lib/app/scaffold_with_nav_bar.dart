import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../features/dashboard/presentation/workspace_menu_sheet.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  void _onItemTapped(int index, BuildContext context) {
    if (index == 3) {
      WorkspaceMenuSheet.show(context);
    } else {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Overview',
                  isSelected: currentIndex == 0,
                  onTap: () => _onItemTapped(0, context),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Accounts',
                  isSelected: currentIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome_rounded,
                  label: 'AI Copilot',
                  isAi: true,
                  isSelected: currentIndex == 2,
                  onTap: () => _onItemTapped(2, context),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.widgets_outlined,
                  activeIcon: Icons.widgets_rounded,
                  label: 'More',
                  isSelected: false,
                  onTap: () => _onItemTapped(3, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isAi = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color activeColor = isAi ? AppColors.aiAccent : AppColors.primary;
    Color inactiveColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAi && isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.aiContainerDark : AppColors.aiContainer,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Icon(
                      activeIcon,
                      size: 20,
                      color: AppColors.aiAccent,
                    ),
                  )
                else
                  Icon(
                    isSelected ? activeIcon : icon,
                    size: 22,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? activeColor : inactiveColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
