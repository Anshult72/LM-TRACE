import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_controller.dart';
import '../theme/app_theme.dart';
import '../constants/app_brand.dart';
import '../widgets/app_logo.dart';
import 'responsive_layout.dart';

/// Interactive collapsible navigation sidebar for LM-TRACE desktop and tablet web.
///
/// Features:
/// - **Collapsed by default**: Behaves as a compact 72px navigation rail showing icons,
///   compact squircle brand mark, active-page indicators, and tooltips.
/// - **Expands on interaction**: Smoothly expands to 250px on mouse hover or keyboard focus,
///   revealing navigation labels, section titles, full branding, and officer controls.
/// - **Collapses automatically**: Returns to the compact rail when interaction ceases.
/// - **Optional pin toggle**: Allows officers to pin the sidebar open when desired.
/// - **Strict RBAC preservation**: Renders only routes permitted for the authenticated officer.
/// - **Zero layout reflow**: Uses smooth layout animation (240ms) without content flashing.
class WebSidebar extends ConsumerStatefulWidget {
  /// Whether the sidebar is forced to collapsed mode externally (e.g. tablet viewport override).
  final bool? isCollapsed;

  const WebSidebar({super.key, this.isCollapsed});

  @override
  ConsumerState<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends ConsumerState<WebSidebar> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPinned = false;

  /// Effective expansion state: expanded if pinned, hovered, or focused by keyboard.
  bool get _isExpanded {
    // If explicitly forced collapsed from parent, obey it unless hovered/pinned
    if (widget.isCollapsed == true && !_isPinned && !_isHovered && !_isFocused) {
      return false;
    }
    return _isPinned || _isHovered || _isFocused;
  }

  void _onPointerEnter(PointerEnterEvent event) {
    if (!_isHovered) {
      setState(() => _isHovered = true);
    }
  }

  void _onPointerExit(PointerExitEvent event) {
    if (_isHovered) {
      setState(() => _isHovered = false);
    }
  }

  void _togglePinned() {
    setState(() => _isPinned = !_isPinned);
  }

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
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isExpanded = _isExpanded;
    final currentWidth = isExpanded ? Breakpoints.sidebarWidth : Breakpoints.collapsedSidebarWidth;

    return FocusScope(
      onFocusChange: (focused) {
        if (_isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      child: MouseRegion(
        onEnter: _onPointerEnter,
        onExit: _onPointerExit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          width: currentWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            border: const Border(right: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
            boxShadow: isExpanded
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                      offset: const Offset(4, 0),
                    ),
                  ]
                : null,
          ),
          child: ClipRect(
            child: OverflowBox(
              minWidth: Breakpoints.collapsedSidebarWidth,
              maxWidth: Breakpoints.sidebarWidth,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: isExpanded ? Breakpoints.sidebarWidth : Breakpoints.collapsedSidebarWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Branding Header
                    _buildBrandHeader(context, isExpanded),
                    const Divider(color: Color(0xFF1E3A5F), height: 1),

                    // 2. Primary Navigation (Filtered by authenticated user role)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section: CORE INSPECTION
                            _buildSectionHeader('CORE INSPECTION', isExpanded),
                            if (user?.canAccessRoute('/dashboard') ?? true)
                              _buildNavItem(
                                context,
                                label: 'Dashboard',
                                icon: Icons.dashboard_outlined,
                                activeIcon: Icons.dashboard,
                                route: '/dashboard',
                                isActive: location == '/dashboard' || location == '/',
                                isExpanded: isExpanded,
                              ),
                            if (user?.canAccessRoute('/inspections') ?? true)
                              _buildNavItem(
                                context,
                                label: 'Inspections Registry',
                                icon: Icons.assignment_outlined,
                                activeIcon: Icons.assignment,
                                route: '/inspections',
                                isActive: location.startsWith('/inspections'),
                                isExpanded: isExpanded,
                              ),
                            if (user?.canAccessRoute('/scanner') ?? false)
                              _buildNavItem(
                                context,
                                label: 'Scan & Ingestion',
                                icon: Icons.qr_code_scanner_outlined,
                                activeIcon: Icons.qr_code_scanner,
                                route: '/scanner',
                                isActive: location.startsWith('/scanner'),
                                isExpanded: isExpanded,
                              ),
                            if (user?.canAccessRoute('/products') ?? true)
                              _buildNavItem(
                                context,
                                label: 'Product Intelligence',
                                icon: Icons.fingerprint_outlined,
                                activeIcon: Icons.fingerprint,
                                route: '/products',
                                isActive: location.startsWith('/products'),
                                isExpanded: isExpanded,
                              ),
                            if (user?.canAccessRoute('/reference-library') ?? true)
                              _buildNavItem(
                                context,
                                label: 'Reference Library',
                                icon: Icons.auto_stories_outlined,
                                activeIcon: Icons.auto_stories,
                                route: '/reference-library',
                                isActive: location.startsWith('/reference-library'),
                                isExpanded: isExpanded,
                              ),
                            if (user?.canAccessRoute('/rules') ?? false)
                              _buildNavItem(
                                context,
                                label: 'Statutory Rule Engine',
                                icon: Icons.gavel_outlined,
                                activeIcon: Icons.gavel,
                                route: '/rules',
                                isActive: location.startsWith('/rules'),
                                isExpanded: isExpanded,
                              ),

                            const SizedBox(height: 8),
                            // Section: ENFORCEMENT & SYSTEM
                            _buildSectionHeader('ENFORCEMENT & SYSTEM', isExpanded),
                            if (user?.canAccessRoute('/calibration') ?? true)
                              _buildNavItem(
                                context,
                                label: 'Scale Calibration',
                                icon: Icons.straighten_outlined,
                                activeIcon: Icons.straighten,
                                route: '/calibration',
                                isActive: location.startsWith('/calibration'),
                                isExpanded: isExpanded,
                              ),
                            if (user?.canAccessRoute('/supervisor') ?? false)
                              _buildNavItem(
                                context,
                                label: 'Supervisor Review',
                                icon: Icons.supervisor_account_outlined,
                                activeIcon: Icons.supervisor_account,
                                route: '/supervisor',
                                isActive: location.startsWith('/supervisor'),
                                isExpanded: isExpanded,
                              ),
                            if (user?.canAccessRoute('/audit-trail') ?? false)
                              _buildNavItem(
                                context,
                                label: 'Audit Trail',
                                icon: Icons.history_edu_outlined,
                                activeIcon: Icons.history_edu,
                                route: '/audit-trail',
                                isActive: location.startsWith('/audit-trail'),
                                isExpanded: isExpanded,
                              ),

                            const SizedBox(height: 8),
                            // Section: SYSTEM
                            _buildSectionHeader('SYSTEM', isExpanded),
                            if (user?.canAccessRoute('/about') ?? true)
                              _buildNavItem(
                                context,
                                label: 'Statutory Reference',
                                icon: Icons.menu_book_outlined,
                                activeIcon: Icons.menu_book,
                                route: '/about',
                                isActive: location.startsWith('/about'),
                                isExpanded: isExpanded,
                              ),
                            if (user?.canAccessRoute('/settings') ?? true)
                              _buildNavItem(
                                context,
                                label: 'System Settings',
                                icon: Icons.settings_outlined,
                                activeIcon: Icons.settings,
                                route: '/settings',
                                isActive: location.startsWith('/settings'),
                                isExpanded: isExpanded,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Footer with Status & Sign Out
                    _buildSidebarFooter(context, ref, user, isExpanded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context, bool isExpanded) {
    if (!isExpanded) {
      return Container(
        height: Breakpoints.topBarHeight,
        alignment: Alignment.center,
        child: const AppLogo.sidebar(
          collapsed: true,
          tooltip: '${AppBrand.name} — ${AppBrand.subtitle}',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 24), // Visual balance spacer for pin button
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const AppLogo.sidebar(
                    collapsed: false,
                  ),
                ),
              ),
              // Pin / Unpin button
              IconButton(
                icon: Icon(
                  _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 16,
                  color: _isPinned ? AppColors.accentGold : const Color(0xFF8DA4C4),
                ),
                tooltip: _isPinned ? 'Unpin sidebar (auto-collapse)' : 'Pin sidebar open',
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: _togglePinned,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            AppBrand.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isExpanded) {
    if (!isExpanded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: Color(0xFF1E3A5F), height: 1, indent: 18, endIndent: 18),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: Color(0xFF8DA4C4),
        ),
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
    required bool isExpanded,
  }) {
    final effectiveColor = isActive ? Colors.white : AppColors.skyGrey;
    final effectiveBg = isActive ? const Color(0xFF163E50) : Colors.transparent;

    Widget navContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: () {
          context.go(route);
        },
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFF133646),
        child: Container(
          height: 42,
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 12 : 0,
          ),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: AppColors.inspectionGreen, width: 1.2)
                : null,
          ),
          alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
          child: Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.mintMist : effectiveColor,
                size: 20,
              ),
              if (isExpanded) ...[
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
                    maxLines: 1,
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accentGold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    // In collapsed mode, provide tooltip describing the destination page.
    if (!isExpanded) {
      return Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 250),
        preferBelow: false,
        verticalOffset: 0,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF071B24),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.inspectionGreen.withValues(alpha: 0.5), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        child: navContent,
      );
    }

    return navContent;
  }

  Widget _buildSidebarFooter(BuildContext context, WidgetRef ref, AuthUser? user, bool isExpanded) {
    if (!isExpanded) {
      return Container(
        height: 56,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
        ),
        child: IconButton(
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 18),
          tooltip: 'Logout',
          onPressed: () => _confirmLogout(context, ref, user),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1F29),
        border: Border(top: BorderSide(color: Color(0xFF163E50), width: 1)),
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
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Engine Online • Rule v2024.1',
                  style: TextStyle(color: AppColors.steelBlue, fontSize: 11, fontWeight: FontWeight.w500),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.alertRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.alertRed.withValues(alpha: 0.25), width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Logout',
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
