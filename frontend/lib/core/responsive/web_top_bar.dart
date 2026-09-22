import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'responsive_layout.dart';

/// Compact enterprise topbar for LM-TRACE desktop and tablet web.
class WebTopBar extends ConsumerWidget {
  final String? location;

  const WebTopBar({super.key, this.location});

  String _getPageTitle(String loc) {
    if (loc.startsWith('/new-inspection')) return 'New Inspection Case';
    if (loc.startsWith('/dashboard') || loc == '/') return 'Operational Dashboard';
    if (loc.startsWith('/inspections/')) return 'Inspection Case File';
    if (loc.startsWith('/inspections')) return 'Inspections Registry';
    if (loc.startsWith('/scanner')) return 'Package Scanner & OCR Workspace';
    if (loc.startsWith('/products')) return 'Product Intelligence & Label Versions';
    if (loc.startsWith('/rules')) return 'Statutory Rule Engine Registry';
    if (loc.startsWith('/calibration')) return 'Scale & Metric Calibration';
    if (loc.startsWith('/supervisor')) return 'Supervisor Enforcement Review';
    if (loc.startsWith('/audit-trail')) return 'Audit Trail';
    if (loc.startsWith('/settings')) return 'System Configuration';
    if (loc.startsWith('/about')) return 'Statutory Standards & About';
    return 'Legal Metrology Compliance';
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, AuthUser? user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out of LM-TRACE?'),
        content: Text(
          'Are you sure you want to end your authenticated session as ${user?.fullName ?? "Officer"} (${user?.role ?? "INSPECTOR"})? You will be returned to the secure login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveLocation = location ?? GoRouterState.of(context).matchedLocation;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isFocusedWorkflow = effectiveLocation.startsWith('/new-inspection') ||
        effectiveLocation.endsWith('/finalize') ||
        effectiveLocation.startsWith('/scanner') ||
        effectiveLocation.startsWith('/analysis-progress');

    return Container(
      height: Breakpoints.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceIvory,
        border: Border(bottom: BorderSide(color: AppColors.skyGrey, width: 1)),
      ),
      child: Row(
        children: [
          // 1. Breadcrumbs / Page Title
          if (!isDesktop) ...[
            const AppLogo.compact(size: 28),
            const SizedBox(width: 10),
          ],
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Legal Metrology',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.steelBlue,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/',
                    style: TextStyle(fontSize: 11, color: AppColors.steelBlue.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getPageTitle(effectiveLocation),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inspectionGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getPageTitle(effectiveLocation),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ContextHelpButton(pageId: effectiveLocation, size: 15),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Role-aware Action Button (hidden on focused workflows)
          if (!isFocusedWorkflow) ...[
            if (user?.isSupervisor == true)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.inspectionGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.rate_review_outlined, size: 16, color: Colors.white),
                label: const Text(
                  'Review Cases',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => context.go('/supervisor'),
              )
            else if (user?.canAccessRoute('/new-inspection') ?? true)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'New Inspection',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => context.go('/new-inspection'),
              ),
            const SizedBox(width: 14),
          ],

          const SizedBox(
            height: 28,
            child: VerticalDivider(color: AppColors.skyGrey, thickness: 1),
          ),
          const SizedBox(width: 12),

          // 3. Officer Profile Badge with Popup Menu
          PopupMenuButton<String>(
            tooltip: 'Officer Profile & Options',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.skyGrey),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                context.go('/profile');
              } else if (value == 'logout') {
                _confirmLogout(context, ref, user);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Officer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user?.role ?? "INSPECTOR"} • ${user?.officerId ?? "LM-001"}',
                      style: const TextStyle(fontSize: 11, color: AppColors.steelBlue),
                    ),
                    const Divider(height: 12, color: AppColors.skyGrey),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: AppColors.primaryNavy),
                    SizedBox(width: 10),
                    Text('View Profile', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.alertRed),
                    SizedBox(width: 10),
                    Text('Sign Out', style: TextStyle(fontSize: 13, color: AppColors.alertRed, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.primaryNavy,
                    child: Text(
                      (user?.fullName ?? 'I').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Inspector',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.mintMist,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                user?.role ?? 'INSPECTOR',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (user?.zone != null && user!.zone.isNotEmpty) ? user.zone : (user?.department ?? 'Legal Metrology'),
                              style: const TextStyle(fontSize: 10.5, color: AppColors.steelBlue),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.steelBlue),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Dedicated Quick Sign Out Icon Button
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 19, color: AppColors.steelBlue),
            tooltip: 'Sign Out of LM-TRACE',
            hoverColor: AppColors.alertRed.withValues(alpha: 0.1),
            onPressed: () => _confirmLogout(context, ref, user),
          ),
        ],
      ),
    );
  }
}
