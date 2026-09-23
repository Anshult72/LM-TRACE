import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_brand.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// Navigation header for the LM-TRACE public landing page.
///
/// Features:
/// - Sticky glassmorphism header matching [AppColors.primaryNavy]
/// - Smooth section anchor navigation on Web
/// - Prominent "Access Platform" CTA leading to `/login`
/// - Accessible mobile menu drawer with smooth animation
class PublicNavbar extends StatefulWidget {
  final VoidCallback? onHowItWorksTap;
  final VoidCallback? onCapabilitiesTap;
  final VoidCallback? onRuleEngineTap;
  final VoidCallback? onEvidenceTap;
  final VoidCallback? onArchitectureTap;
  final VoidCallback? onAboutTap;
  final String activeSection;
  final bool isScrolled;

  const PublicNavbar({
    super.key,
    this.onHowItWorksTap,
    this.onCapabilitiesTap,
    this.onRuleEngineTap,
    this.onEvidenceTap,
    this.onArchitectureTap,
    this.onAboutTap,
    this.activeSection = '',
    this.isScrolled = false,
  });

  @override
  State<PublicNavbar> createState() => _PublicNavbarState();
}

class _PublicNavbarState extends State<PublicNavbar> {
  bool _mobileMenuOpen = false;

  void _closeMenu() {
    if (_mobileMenuOpen) {
      setState(() => _mobileMenuOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    final bgColor = widget.isScrolled
        ? AppColors.primaryNavy.withValues(alpha: 0.98)
        : AppColors.primaryNavy;

    final borderColor = widget.isScrolled
        ? const Color(0xFF163E50)
        : const Color(0xFF123444);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 68,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
            boxShadow: widget.isScrolled ? AppShadows.md : null,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Brand Identity
                    InkWell(
                      onTap: () {
                        _closeMenu();
                        // Scroll to top
                      },
                      borderRadius: AppRadii.sm,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLogo.compact(
                            size: 38,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    AppBrand.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.inspectionGreen.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.inspectionGreen,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Text(
                                      'GOV',
                                      style: TextStyle(
                                        color: AppColors.mintMist,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isMobile ? 'Compliance Platform' : 'Legal Metrology Compliance & Inspection',
                                style: const TextStyle(
                                  color: AppColors.sage,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Desktop Navigation Links
                    if (!isMobile) ...[
                      _NavLink(
                        label: 'How It Works',
                        isActive: widget.activeSection == 'how_it_works',
                        onTap: widget.onHowItWorksTap,
                      ),
                      _NavLink(
                        label: 'Capabilities',
                        isActive: widget.activeSection == 'capabilities',
                        onTap: widget.onCapabilitiesTap,
                      ),
                      _NavLink(
                        label: 'Rule Engine',
                        isActive: widget.activeSection == 'rules',
                        onTap: widget.onRuleEngineTap,
                      ),
                      _NavLink(
                        label: 'Evidence',
                        isActive: widget.activeSection == 'evidence',
                        onTap: widget.onEvidenceTap,
                      ),
                      _NavLink(
                        label: 'Architecture',
                        isActive: widget.activeSection == 'architecture',
                        onTap: widget.onArchitectureTap,
                      ),
                      _NavLink(
                        label: 'About',
                        isActive: widget.activeSection == 'about',
                        onTap: widget.onAboutTap,
                      ),
                      const SizedBox(width: 16),
                      // Prominent Login Button
                      _LoginButton(),
                    ] else ...[
                      // Mobile Menu Toggle
                      IconButton(
                        onPressed: () {
                          setState(() => _mobileMenuOpen = !_mobileMenuOpen);
                        },
                        icon: Icon(
                          _mobileMenuOpen ? Icons.close_rounded : Icons.menu_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        tooltip: 'Toggle navigation menu',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Mobile dropdown panel
        if (isMobile && _mobileMenuOpen)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            color: AppColors.primaryNavy,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MobileNavLink(
                  label: 'How It Works',
                  icon: Icons.alt_route_rounded,
                  isActive: widget.activeSection == 'how_it_works',
                  onTap: () {
                    _closeMenu();
                    widget.onHowItWorksTap?.call();
                  },
                ),
                _MobileNavLink(
                  label: 'Capabilities',
                  icon: Icons.grid_view_rounded,
                  isActive: widget.activeSection == 'capabilities',
                  onTap: () {
                    _closeMenu();
                    widget.onCapabilitiesTap?.call();
                  },
                ),
                _MobileNavLink(
                  label: 'Statutory Rule Engine',
                  icon: Icons.gavel_rounded,
                  isActive: widget.activeSection == 'rules',
                  onTap: () {
                    _closeMenu();
                    widget.onRuleEngineTap?.call();
                  },
                ),
                _MobileNavLink(
                  label: 'Evidence Traceability',
                  icon: Icons.verified_user_outlined,
                  isActive: widget.activeSection == 'evidence',
                  onTap: () {
                    _closeMenu();
                    widget.onEvidenceTap?.call();
                  },
                ),
                _MobileNavLink(
                  label: 'Architecture',
                  icon: Icons.hub_outlined,
                  isActive: widget.activeSection == 'architecture',
                  onTap: () {
                    _closeMenu();
                    widget.onArchitectureTap?.call();
                  },
                ),
                _MobileNavLink(
                  label: 'About & Mandate',
                  icon: Icons.info_outline_rounded,
                  isActive: widget.activeSection == 'about',
                  onTap: () {
                    _closeMenu();
                    widget.onAboutTap?.call();
                  },
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF163E50), height: 1),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _closeMenu();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Login to LM-TRACE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.inspectionGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _NavLink({
    required this.label,
    this.onTap,
    this.isActive = false,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  color: (active || _isHovered) ? AppColors.mintMist : const Color(0xFFD9E2EA),
                  fontSize: 13.5,
                  fontWeight: active ? FontWeight.w700 : (_isHovered ? FontWeight.w600 : FontWeight.w500),
                ),
                child: Text(widget.label),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2.5,
                width: active ? 24 : 0,
                decoration: BoxDecoration(
                  color: AppColors.inspectionGreen,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.inspectionGreen.withValues(alpha: 0.6),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatefulWidget {
  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF236355) : AppColors.inspectionGreen,
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.inspectionGreen.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.go('/login'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Access Platform',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _MobileNavLink({
    required this.label,
    required this.icon,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.inspectionGreen.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? AppColors.mintMist : AppColors.sage, size: 18),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.mintMist : const Color(0xFFF1F5F9),
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: isActive ? AppColors.mintMist : AppColors.steelBlue,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
