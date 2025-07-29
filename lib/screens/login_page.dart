import 'package:exfactor/screens/admin/admin_main_screen.dart';
import 'package:exfactor/screens/supervisor/supervisor_main_screen.dart';
import 'package:exfactor/screens/technical/technical_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //initialized email, and password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _biometricsAvailable = false;
  bool _biometricEnabled = false;
  final LocalAuthentication auth = LocalAuthentication();
  bool _obscurePassword = true; // Added for password visibility

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    _checkBiometrics().then((available) {
      setState(() {
        _biometricsAvailable = available;
      });
      _loadBiometricEnabled();
    });
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _loadBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

  Future<void> _performLogin(String email, String password) async {
    try {
      final userData = await SupabaseService.getUserByEmail(email);
      if (userData == null) {
        _showToast("User not found in database.");
        return;
      }
      final userModel = UserModel.fromMap(userData);

      // Save session after successful login
      await _saveUserSession(userModel);

      // Prompt to enable biometrics
      await _promptEnableBiometrics();

      _navigateToUserScreen(userModel);
    } catch (e) {
      _showToast("Login failed: ${e.toString()}");
    }
  }

  Future<void> _promptEnableBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    // Only prompt if biometrics are available and not already enabled
    if (_biometricsAvailable &&
        !(prefs.getBool('biometric_enabled') ?? false)) {
      final enable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enable Biometric Login?'),
          content: Text(
              'Would you like to enable fingerprint/face login for future sign-ins?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        ),
      );
      if (enable == true) {
        await prefs.setBool('biometric_enabled', true);
        _showToast('Biometric login enabled!');
      }
    }
  }

  Future<void> _saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'user_name', (user.firstName ?? '') + ' ' + (user.lastName ?? ''));
    await prefs.setString('role', user.role ?? '');
    await prefs.setInt('member_id', user.memberId);
    print(
        'Session saved: member_id= [32m${user.memberId} [0m, role= [32m${user.role} [0m');
  }

  Future<void> _clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('role');
    await prefs.remove('member_id');
  }

  void _navigateToUserScreen(UserModel userModel) {
    if (userModel.role == 'Supervisor') {
      Navigator.push(context, MaterialPageRoute(builder: (_) {
        return SupervisorMainScreen(user: userModel);
      }));
    } else if (userModel.role == 'Admin') {
      Navigator.push(context, MaterialPageRoute(builder: (_) {
        return AdminMainScreen(user: userModel);
      }));
    } else if (userModel.role == 'Technician') {
      Navigator.push(context, MaterialPageRoute(builder: (_) {
        return TechnicalMainScreen(user: userModel);
      }));
    } else {
      _showToast("No role found for this user.");
    }
  }

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showToast("Please enter email address or username");
      return;
    } else if (password.isEmpty) {
      _showToast("Please enter your password");
      return;
    }

    // Remember Me logic
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', email);
    } else {
      await prefs.remove('saved_email');
    }

    await _performLogin(email, password);
  }

  Future<bool> _checkBiometrics() async {
    return await auth.canCheckBiometrics;
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      // Error handling for production
      return false;
    }
  }

  Future<void> _loginWithSavedSessionOrCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getInt('member_id');
    final role = prefs.getString('role');

    if (memberId != null && role != null) {
      final userData = await SupabaseService.getUserByMemberId(memberId);
      if (userData != null) {
        final userModel = UserModel.fromMap(userData);
        _navigateToUserScreen(userModel);
        return;
      }
    }
    _showToast('No saved session found. Please login with email and password.');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Exfactor.png',
                      height: 70,
                    ),
                    const Text(
                      'Lead The Change',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(221, 80, 58, 58),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 100),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Enter Your Credential",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF001F54),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Enter Email or user name',
                          hintStyle: const TextStyle(fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.blueGrey),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          final emailRegex =
                              RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                          if (!emailRegex.hasMatch(val))
                            return 'Enter a valid email address';
                          return null;
                        }),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword, // Updated
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blueGrey),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        const Text('Remember Me'),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001F54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Sign in",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_biometricsAvailable && _biometricEnabled)
                      ElevatedButton.icon(
                        icon: Icon(Icons.fingerprint),
                        label: Text('Login with Fingerprint/Face'),
                        onPressed: () async {
                          bool authenticated =
                              await _authenticateWithBiometrics();
                          if (authenticated) {
                            await _loginWithSavedSessionOrCredentials();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Biometric authentication failed')),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}

void _showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.red,
    textColor: Colors.white,
    fontSize: 14.0,
  );
}

void handleLogout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user_name');
  await prefs.remove('role');
  await prefs.remove('member_id');
  // Do NOT remove 'biometric_enabled' so biometric login remains enabled after logout

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => LoginPage()),
    (route) => false,
  );
}
