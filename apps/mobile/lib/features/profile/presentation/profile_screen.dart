import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/finoryx_card.dart';
import '../../../core/widgets/finoryx_section_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        children: [
          // Profile Avatar Hero
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'B',
                    style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (user?.fullName.isNotEmpty == true) ? user!.fullName : 'Benison T R',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (user?.email.isNotEmpty == true) ? user!.email : 'benison@finoryx.io',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Preferences Inset Card
          const FinoryxSectionHeader(title: 'Preferences'),
          FinoryxCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary, size: 20),
                  title: const Text('Base Currency', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: Text(
                    user?.baseCurrency ?? 'INR (₹)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: AppColors.primary, size: 20),
                  title: const Text('Categories & Tags', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Manage custom taxonomies', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => context.push('/categories'),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 20),
                  title: const Text('Biometric Security', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Fingerprint or Face ID unlock', style: TextStyle(fontSize: 12)),
                  value: user?.biometricEnabled ?? false,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) async {
                    if (val) {
                      final biometrics = ref.read(biometricServiceProvider);
                      final available = await biometrics.isBiometricsAvailable();
                      if (!available) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Biometrics (Fingerprint / Face ID) are not available on this device or browser.'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        }
                        return;
                      }

                      final authenticated = await biometrics.authenticate(
                        reason: 'Confirm biometrics to enable fingerprint/face unlock',
                      );
                      if (!authenticated) return;
                    }

                    await ref.read(authNotifierProvider.notifier).setBiometricEnabled(val);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Biometric authentication enabled!' : 'Biometric authentication disabled.'),
                          backgroundColor: AppColors.income,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Account Actions Inset Card
          const FinoryxSectionHeader(title: 'Account Actions'),
          FinoryxCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.expense, size: 20),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors.expense,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.expense),
              onTap: () async {
                final router = GoRouter.of(context);
                await ref.read(authNotifierProvider.notifier).signOut();
                if (!mounted) return;
                router.go('/login');
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
