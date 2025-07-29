import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exfactor/screens/login_page.dart';
import 'package:exfactor/screens/admin/admin_main_screen.dart';
import 'package:exfactor/screens/supervisor/supervisor_main_screen.dart';
import 'package:exfactor/screens/technical/technical_main_screen.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/models/user_model.dart';
import 'package:local_auth/local_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _handleBiometricFirstLogin();
  }

  Future<void> _handleBiometricFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    final canCheckBiometrics = await auth.canCheckBiometrics;
    final isDeviceSupported = await auth.isDeviceSupported();

    if (biometricEnabled && canCheckBiometrics && isDeviceSupported) {
      try {
        final didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to access your account',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        if (didAuthenticate) {
          await _loginWithSavedSessionOrCredentials();
          return;
        }
      } catch (e) {
        // If biometric fails, fall through to login page
      }
    }
    // If not enabled, not available, or failed, go to login page
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => LoginPage()));
  }

  Future<void> _loginWithSavedSessionOrCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getInt('member_id');
    final role = prefs.getString('role');

    if (memberId != null && role != null) {
      final userData = await SupabaseService.getUserByMemberId(memberId);
      if (userData != null) {
        final userModel = UserModel.fromMap(userData);
        if (role == 'Admin') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => AdminMainScreen(user: userModel)));
          return;
        } else if (role == 'Supervisor') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => SupervisorMainScreen(user: userModel)));
          return;
        } else if (role == 'Technician') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => TechnicalMainScreen(user: userModel)));
          return;
        }
      }
    }
    // If not logged in or user not found, go to login page
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/images/Exfactor.png', height: 100),
      ),
    );
  }
}
