import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_controller.dart';
import '../theme/app_theme.dart';
import '../constants/app_brand.dart';
import '../widgets/app_logo.dart';
import 'responsive_layout.dart';

/// Persistent enterprise left sidebar for LM-TRACE desktop and tablet web.
class WebSidebar extends ConsumerWidget {
  final bool isCollapsed;

  const WebSidebar({super.key, this.isCollapsed = false});

  void _confirmLogout(BuildContext context, WidgetRef ref, AuthUser? user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out of LM-TRACE?'),
        content: Text(
          'Are you sure you want to terminate your authenticated session as ${user?.fullName ?? "Officer"} (${user?.role ?? "INSPECTOR"})? You will be returned to the secure login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violationRed,
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
    final location = GoRouterState.of(context).matchedLocation;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Container(
      width: isCollapsed ? Breakpoints.collapsedSidebarWidth : Breakpoints.sidebarWidth,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryNavy,
        border: Border(right: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Branding Header
          _buildBrandHeader(context),
          const Divider(color: Color(0xFF1E3A5F), height: 1),

          // 2. Primary Navigation (Filtered by authenticated user role)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCollapsed)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      child: Text(
                        'CORE INSPECTION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: Color(0xFF8DA4C4),
                        ),
                      ),
                    ),
                  if (user?.canAccessRoute('/dashboard') ?? true)
                    _buildNavItem(
                      context,
                      label: 'Dashboard',
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      route: '/dashboard',
                      isActive: location == '/dashboard' || location == '/',
                    ),
                  if (user?.canAccessRoute('/inspections') ?? true)
                    _buildNavItem(
                      context,
                      label: 'Inspections Registry',
                      icon: Icons.assignment_outlined,
                      activeIcon: Icons.assignment,
                      route: '/inspections',
                      isActive: location.startsWith('/inspections'),
                    ),
                  if (user?.canAccessRoute('/scanner') ?? false)
                    _buildNavItem(
                      context,
                      label: 'Scan & Ingestion',
                      icon: Icons.qr_code_scanner_outlined,
                      activeIcon: Icons.qr_code_scanner,
                      route: '/scanner',
                      isActive: location.startsWith('/scanner'),
                    ),
                  if (user?.canAccessRoute('/products') ?? true)
                    _buildNavItem(
                      context,
                      label: 'Product Intelligence',
                      icon: Icons.fingerprint_outlined,
                      activeIcon: Icons.fingerprint,
                      route: '/products',
                      isActive: location.startsWith('/products'),
                    ),
                  if (user?.canAccessRoute('/reference-library') ?? true)
                    _buildNavItem(
                      context,
                      label: 'Reference Library',
                      icon: Icons.auto_stories_outlined,
                      activeIcon: Icons.auto_stories,
                      route: '/reference-library',
                      isActive: location.startsWith('/reference-library'),
                    ),
                  if (user?.canAccessRoute('/rules') ?? false)
                    _buildNavItem(
                      context,
                      label: 'Statutory Rule Engine',
                      icon: Icons.gavel_outlined,
                      activeIcon: Icons.gavel,
                      route: '/rules',
                      isActive: location.startsWith('/rules'),
                    ),

                  const SizedBox(height: 14),
                  if (!isCollapsed) ...[
                    const Divider(color: Color(0xFF1E3A5F), height: 1),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      child: Text(
                        'ENFORCEMENT & SYSTEM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: Color(0xFF8DA4C4),
                        ),
                      ),
                    ),
                  ],
                  if (user?.canAccessRoute('/calibration') ?? true)
                    _buildNavItem(
                      context,
                      label: 'Scale Calibration',
                      icon: Icons.straighten_outlined,
                      activeIcon: Icons.straighten,
                      route: '/calibration',
                      isActive: location.startsWith('/calibration'),
                    ),
                  if (user?.canAccessRoute('/supervisor') ?? false)
                    _buildNavItem(
                      context,
                      label: 'Supervisor Review',
                      icon: Icons.supervisor_account_outlined,
                      activeIcon: Icons.supervisor_account,
                      route: '/supervisor',
                      isActive: location.startsWith('/supervisor'),
                    ),
                  if (user?.canAccessRoute('/audit-trail') ?? false)
                    _buildNavItem(
                      context,
                      label: 'Audit Trail',
                      icon: Icons.history_edu_outlined,
                      activeIcon: Icons.history_edu,
                      route: '/audit-trail',
                      isActive: location.startsWith('/audit-trail'),
                    ),
                  if (user?.canAccessRoute('/statutory-reference') ?? true)
                    _buildNavItem(
                      context,
                      label: 'Statutory Reference',
                      icon: Icons.menu_book_outlined,
                      activeIcon: Icons.menu_book,
                      route: '/statutory-reference',
                      isActive: location.startsWith('/statutory-reference') || location.startsWith('/about'),
                    ),
                  if (user?.canAccessRoute('/settings') ?? false)
                    _buildNavItem(
                      context,
                      label: 'System Settings',
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      route: '/settings',
                      isActive: location.startsWith('/settings'),
                    ),
                ],
              ),
            ),
          ),

          // 3. Footer with Status & Sign Out
          _buildSidebarFooter(context, ref, user),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    if (isCollapsed) {
      return Container(
        height: Breakpoints.topBarHeight,
        alignment: Alignment.center,
        child: const AppLogo.compact(
          size: 42,
          tooltip: '${AppBrand.name} — ${AppBrand.subtitle}',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 195, maxHeight: 110),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const AppLogo(
                fit: BoxFit.contain,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF2E4D7A), width: 0.8),
              ),
              child: const Text(
                'Legal Metrology • Govt. of India',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required String route,
    required bool isActive,
  }) {
    final effectiveColor = isActive ? Colors.white : const Color(0xFFCBD5E1);
    final effectiveBg = isActive ? const Color(0xFF1E3A5F) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFF162D4A),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 0 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: AppColors.accentBlue.withValues(alpha: 0.5), width: 1)
                : null,
          ),
          alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? const Color(0xFF60A5FA) : effectiveColor,
                size: 20,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: effectiveColor,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF60A5FA),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(BuildContext context, WidgetRef ref, AuthUser? user) {
    if (isCollapsed) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: IconButton(
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 18),
          tooltip: 'Sign Out (${user?.fullName ?? "Officer"})',
          onPressed: () => _confirmLogout(context, ref, user),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1B29),
        border: Border(top: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Engine Online • Rule v2024.1',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _confirmLogout(context, ref, user),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25), width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Sign Out of LM-TRACE',
                    style: TextStyle(
                      color: Color(0xFFF87171),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
