import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import 'auth_controller.dart';

/// Professional 403 Forbidden Access Denied Screen for unauthorized RBAC routes.
class AccessDeniedScreen extends ConsumerWidget {
  final String? attemptedRoute;

  const AccessDeniedScreen({super.key, this.attemptedRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final role = user?.role ?? 'UNAUTHENTICATED';

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.xl,
                border: Border.all(color: AppColors.borderLight, width: 1.2),
                boxShadow: AppShadows.lg,
              ),
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Seal / Shield Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.violationRedLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.violationRedBorder, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.violationRed,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 403 Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.violationRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.violationRed.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      '403 • STATUTORY ACCESS FORBIDDEN',
                      style: TextStyle(
                        color: AppColors.violationRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  const Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle description
                  Text(
                    'Your authenticated role ($role) does not hold the statutory delegation required to access this operational module${attemptedRoute != null ? ' ($attemptedRoute)' : ''}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Officer Credential Verification Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryNavy,
                          child: Text(
                            (user?.fullName ?? 'O').substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Enforcement Officer',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${user?.officerId ?? 'LM-001'} • ${user?.department ?? 'Legal Metrology'}',
                                style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.neutral200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neutral800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.neutral300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.violationRed),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(color: AppColors.violationRed, fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Dashboard',
                          icon: Icons.dashboard_outlined,
                          size: AppButtonSize.md,
                          onPressed: () => context.go('/dashboard'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
