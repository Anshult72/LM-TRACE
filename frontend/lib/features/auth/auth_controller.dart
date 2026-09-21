import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String officerId;
  final String department;
  final String role;
  final String zone;

  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.officerId,
    required this.department,
    required this.role,
    this.zone = '',
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? 'Officer',
      officerId: json['officer_id'] ?? json['officerId'] ?? 'LM-001',
      department: json['department'] ?? 'Legal Metrology',
      role: json['role'] ?? 'INSPECTOR',
      zone: json['zone'] ?? '',
    );
  }
  bool get isInspector => role.toUpperCase() == 'INSPECTOR';
  bool get isSupervisor => role.toUpperCase() == 'SUPERVISOR';
  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  /// Determines whether the authenticated officer has permission to access [route].
  bool canAccessRoute(String route) {
    final cleanRoute = route.split('?').first;

    // Universal routes accessible to all authenticated officers
    if (cleanRoute == '/' ||
        cleanRoute == '/dashboard' ||
        cleanRoute.startsWith('/inspections') ||
        cleanRoute.startsWith('/products') ||
        cleanRoute.startsWith('/reference-library') ||
        cleanRoute.startsWith('/calibration') ||
        cleanRoute.startsWith('/statutory-reference') ||
        cleanRoute.startsWith('/about') ||
        cleanRoute.startsWith('/profile') ||
        cleanRoute.startsWith('/evidence') ||
        cleanRoute.startsWith('/reports') ||
        cleanRoute.startsWith('/online-listing') ||
        cleanRoute.startsWith('/access-denied')) {
      return true;
    }

    // Field capture & scanning: Inspector & Admin
    if (cleanRoute.startsWith('/scanner') ||
        cleanRoute.startsWith('/scan') ||
        cleanRoute.startsWith('/new-inspection') ||
        cleanRoute.startsWith('/analysis-progress')) {
      return isInspector || isAdmin;
    }

    // Supervisory enforcement review: Supervisor & Admin
    if (cleanRoute.startsWith('/supervisor')) {
      return isSupervisor || isAdmin;
    }

    // Statutory Rule Engine view/manage: Supervisor & Admin
    if (cleanRoute.startsWith('/rules')) {
      return isSupervisor || isAdmin;
    }

    // Audit trail oversight: Supervisor & Admin
    if (cleanRoute.startsWith('/audit-trail')) {
      return isSupervisor || isAdmin;
    }

    // System Settings & configuration: Admin only
    if (cleanRoute.startsWith('/settings')) {
      return isAdmin;
    }

    return false;
  }
}

typedef UserModel = AuthUser;

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final AuthUser? user;
  final String? errorMessage;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    AuthUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState());

  Future<void> checkAuthStatus() async {
    if (state.isAuthenticated) return;
    try {
      final response = await _apiClient.get(ApiConstants.me);
      if (response.statusCode == 200) {
        final user = AuthUser.fromJson(response.data);
        state = state.copyWith(isAuthenticated: true, user: user);
      }
    } catch (_) {
      // Stay unauthenticated if no stored session
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['access_token'];
        final userJson = data['user'];
        final user = AuthUser.fromJson(userJson);

        _apiClient.setAuthToken(token);
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: user,
          errorMessage: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "Invalid officer ID or password",
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Could not connect to LM-TRACE server. Please verify backend is running.",
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } catch (_) {
      // Swallowed so frontend logout always cleanly completes even if offline
    } finally {
      _apiClient.setAuthToken(null);
      state = AuthState();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client);
});
