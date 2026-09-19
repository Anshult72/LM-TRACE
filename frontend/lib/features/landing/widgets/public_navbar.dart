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
  final bool isScrolled;

  const PublicNavbar({
    super.key,
    this.onHowItWorksTap,
    this.onCapabilitiesTap,
    this.onRuleEngineTap,
    this.onEvidenceTap,
    this.onArchitectureTap,
    this.onAboutTap,
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
        ? AppColors.primaryNavy.withValues(alpha: 0.96)
        : AppColors.primaryNavy;

    final borderColor = widget.isScrolled
        ? const Color(0xFF1E3A5F)
        : const Color(0xFF162D47);

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
                                      color: AppColors.accentBlue.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.accentBlue.withValues(alpha: 0.5),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Text(
                                      'GOV',
                                      style: TextStyle(
                                        color: Color(0xFF93C5FD),
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
                                  color: Color(0xFF94A3B8),
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
                      _NavLink(label: 'How It Works', onTap: widget.onHowItWorksTap),
                      _NavLink(label: 'Capabilities', onTap: widget.onCapabilitiesTap),
                      _NavLink(label: 'Rule Engine', onTap: widget.onRuleEngineTap),
                      _NavLink(label: 'Evidence', onTap: widget.onEvidenceTap),
                      _NavLink(label: 'Architecture', onTap: widget.onArchitectureTap),
                      _NavLink(label: 'About', onTap: widget.onAboutTap),
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
            color: const Color(0xFF0C1D2C),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MobileNavLink(
                  label: 'How It Works',
                  icon: Icons.alt_route_rounded,
                  onTap: () {
                    _closeMenu();
                    widget.onHowItWorksTap?.call();
                  },
                ),
                _MobileNavLink(
                  label: 'Capabilities',
                  icon: Icons.grid_view_rounded,
                  onTap: () {
                    _closeMenu();
                    widget.onCapabilitiesTap?.call();
                  },
                ),
                _MobileNavLink(
                  label: 'Statutory Rule Engine',
                  icon: Icons.gavel_rounded,
                  onTap: () {
                    _closeMenu();
                    widget.onRuleEngineTap?.call();
                  },
                ),
                _MobileNavLink(
                  label: 'Evidence Traceability',
                  icon: Icons.verified_user_outlined,
                  onTap: () {
                    _closeMenu();
                    widget.onEvidenceTap?.call();
                  },
                ),
                _MobileNavLink(
                  label: 'Architecture',
                  icon: Icons.hub_outlined,
                  onTap: () {
                    _closeMenu();
                    widget.onArchitectureTap?.call();
                  },
                ),
                _MobileNavLink(
                  label: 'About & Mandate',
                  icon: Icons.info_outline_rounded,
                  onTap: () {
                    _closeMenu();
                    widget.onAboutTap?.call();
                  },
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF1E3A5F), height: 1),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _closeMenu();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Login to LM-TRACE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
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

  const _NavLink({required this.label, this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: _isHovered ? Colors.white : const Color(0xFFCBD5E1),
              fontSize: 13.5,
              fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(widget.label),
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
          color: _isHovered ? const Color(0xFF1D4ED8) : AppColors.accentBlue,
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.4),
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
  final VoidCallback onTap;

  const _MobileNavLink({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8DA4C4), size: 18),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 18),
          ],
        ),
      ),
    );
  }
}
