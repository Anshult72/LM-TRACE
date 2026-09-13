import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_brand.dart';
import '../../core/widgets/widgets.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: "inspector@demo.gov.in");
  final _passwordController = TextEditingController(text: "Inspector@123");
  String _selectedRole = "inspector";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillCredentials(String role, String email, String password) {
    setState(() {
      _selectedRole = role;
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  Future<void> _handleLogin() async {
    await ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      body: Stack(
        children: [
          // Ambient background glow
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentBlue.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 440,
              height: 440,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadii.xl,
                      border: Border.all(color: AppColors.borderLight, width: 1.2),
                      boxShadow: AppShadows.lg,
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Official LM-TRACE Brand Logo
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppShadows.glow(AppColors.primaryNavy, opacity: 0.15),
                            ),
                            child: const AppLogo(
                              size: 82,
                              borderRadius: BorderRadius.all(Radius.circular(18)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Center(
                          child: Text(
                            AppBrand.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            "AI-Assisted Legal Metrology Inspection & Compliance",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Error Banner
                        if (authState.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.violationRedLight,
                              borderRadius: AppRadii.sm,
                              border: Border.all(color: AppColors.violationRedBorder),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.violationRed),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.violationRed,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Email / Officer ID
                        AppTextField(
                          controller: _emailController,
                          label: "Officer ID / Email",
                          hintText: "inspector@demo.gov.in",
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        AppTextField(
                          controller: _passwordController,
                          label: "Security Password",
                          hintText: "••••••••••••",
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 24),

                        // Login Action Button
                        AppButton(
                          label: "Secure Inspector Access",
                          icon: Icons.login_rounded,
                          size: AppButtonSize.lg,
                          isFullWidth: true,
                          isLoading: authState.isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 24),

                        // Quick Demo Account Selector
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.borderLight)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                "DEMO ROLE ACCESS",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: AppColors.textMuted.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.borderLight)),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Role Selector Pills
                        Row(
                          children: [
                            _buildRoleChip("Inspector", "inspector", "inspector@demo.gov.in", "Inspector@123"),
                            const SizedBox(width: 8),
                            _buildRoleChip("Supervisor", "supervisor", "supervisor@demo.gov.in", "Supervisor@123"),
                            const SizedBox(width: 8),
                            _buildRoleChip("Admin", "admin", "admin@demo.gov.in", "Admin@123"),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Official Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.passGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Flexible(
                              child: Text(
                                "Legal Metrology Department • Government of India",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
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
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, String roleKey, String email, String password) {
    final isSelected = _selectedRole == roleKey;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _fillCredentials(roleKey, email, password),
          borderRadius: AppRadii.sm,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryNavy : AppColors.neutral50,
              borderRadius: AppRadii.sm,
              border: Border.all(
                color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
                width: 1.1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.neutral700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
