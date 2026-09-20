import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/finoryx_card.dart';

class WorkspaceMenuSheet extends ConsumerWidget {
  const WorkspaceMenuSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WorkspaceMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workspace Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Quick access & navigation',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Active User Profile Card
              FinoryxCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'B',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Benison T R',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            user?.email ?? 'Personal Workspace',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.incomeContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Quick Actions Header
              Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 2-Column Action Grid
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      iconBg: const Color(0xFFE0E7FF),
                      iconColor: const Color(0xFF4338CA),
                      label: 'Accounts',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/accounts');
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildActionTile(
                      context,
                      icon: Icons.category_outlined,
                      iconBg: const Color(0xFFFCE7F3),
                      iconColor: const Color(0xFFBE185D),
                      label: 'Categories',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/categories');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      context,
                      icon: Icons.pie_chart_outline,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFB45309),
                      label: 'Budgets',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/budgets');
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildActionTile(
                      context,
                      icon: Icons.auto_awesome_outlined,
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF7E22CE),
                      label: 'AI Assistant',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/assistant');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      context,
                      icon: Icons.receipt_long_outlined,
                      iconBg: const Color(0xFFCCFBF1),
                      iconColor: const Color(0xFF0F766E),
                      label: 'Reports',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/reports');
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildActionTile(
                      context,
                      icon: Icons.flag_outlined,
                      iconBg: const Color(0xFFDBEAFE),
                      iconColor: const Color(0xFF1D4ED8),
                      label: 'Goals',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/goals');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              // Settings & Sign Out Tiles
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                  child: Icon(Icons.settings_outlined, size: 18, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
                title: Text(
                  'Settings & Preferences',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.expenseContainer,
                  child: Icon(Icons.logout_rounded, size: 18, color: AppColors.expense),
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.expense,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FinoryxCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark ? iconColor.withValues(alpha: 0.2) : iconBg,
            child: Icon(icon, size: 18, color: isDark ? iconColor : iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
