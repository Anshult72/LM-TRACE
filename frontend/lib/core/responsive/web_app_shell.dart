import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'responsive_layout.dart';
import 'web_sidebar.dart';
import 'web_top_bar.dart';

/// Master responsive application shell for LM-TRACE.
///
/// On Desktop & Tablet Web:
/// - Renders persistent left navigation sidebar
/// - Renders compact enterprise topbar
/// - Eliminates mobile bottom navigation
/// - Provides clean scrollable workspace container
///
/// On Mobile / Android:
/// - Renders the existing mobile layout with bottom navigation untouched.
class WebAppShell extends StatelessWidget {
  final Widget child;
  final Widget mobileChild;
  final String? location;

  const WebAppShell({
    super.key,
    required this.child,
    required this.mobileChild,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    // If running on native mobile or small viewport, keep exact existing mobile UI.
    if (ResponsiveLayout.isMobile(context)) {
      return mobileChild;
    }


    return Scaffold(
      backgroundColor: AppColors.surfaceIvory,
      body: Row(
        children: [
          // Left persistent collapsible sidebar (starts collapsed by default)
          const WebSidebar(),

          // Right main area
          Expanded(
            child: Column(
              children: [
                // Compact topbar with live location tracking
                WebTopBar(location: location),

                // Scrollable main page content
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
