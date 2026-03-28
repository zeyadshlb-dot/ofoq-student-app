import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ofoq_student_app/core/api/api_provider.dart';
import 'package:ofoq_student_app/core/api/end_points.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? token;
  final Map<String, dynamic>? studentData;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.token,
    this.studentData,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkLoginStatus();
    return AuthState.initial();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      await getProfile(token);
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return '${androidInfo.manufacturer} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      return linuxInfo.prettyName;
    }
    return 'Unknown Device';
  }

  Future<void> login(String phone, String password, String domain) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final api = ref.read(apiConsumerProvider);
      final deviceName = await _getDeviceName();

      final response = await api.post(
        EndPoints.login,
        data: {
          'tenant_slug': domain,
          'phone': phone,
          'password': password,
          'device_name': deviceName,
          'device_type': Platform.isAndroid || Platform.isIOS
              ? 'mobile'
              : 'desktop',
          'device_fingerprint':
              'flutter_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final token = response['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      await getProfile(token);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final api = ref.read(apiConsumerProvider);
      final response = await api.post(EndPoints.register, data: data);

      final token = response['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      await getProfile(token);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> getProfile(String token) async {
    try {
      final api = ref.read(apiConsumerProvider);
      // The Dio AuthInterceptor automatically adds the Bearer Token
      final response = await api.get(EndPoints.studentProfile);

      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        studentData: response['data'] ?? response,
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}
