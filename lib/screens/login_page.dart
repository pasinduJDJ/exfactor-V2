import 'package:exfactor/screens/admin/admin_main_screen.dart';
import 'package:exfactor/screens/supervisor/supervisor_main_screen.dart';
import 'package:exfactor/screens/technical/technical_main_screen.dart';
import 'package:exfactor/screens/Sales/sale_main_screen.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io';

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

  // Network connectivity check
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

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
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    print('DEBUG: Loading biometric enabled: $biometricEnabled');

    setState(() {
      _biometricEnabled = biometricEnabled;
    });
  }

  Future<void> _performLogin(String email, String password) async {
    try {
      // Check internet connection first
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        _showToast(
            "No internet connection. Please check your network and try again.");
        return;
      }

      final userData = await SupabaseService.getUserByEmail(email);
      if (userData == null) {
        _showToast("Invalid email or password.");
        return;
      }

      // Debug logging to troubleshoot the issue
      print('DEBUG: User data retrieved: ${userData.keys.toList()}');
      print(
          'DEBUG: Password field exists: ${userData.containsKey('password')}');
      print('DEBUG: Stored password: ${userData['password']}');
      print('DEBUG: Input password: $password');

      // CRITICAL SECURITY FIX: Validate password
      final storedPassword = userData['password'] ?? '';
      if (password != storedPassword) {
        _showToast("Invalid email or password.");
        return;
      }

      final userModel = UserModel.fromMap(userData);

      // Save session after successful login
      await _saveUserSession(userModel);

      // Prompt to enable biometrics
      await _promptEnableBiometrics();

      _navigateToUserScreen(userModel);
    } catch (e) {
      // Handle specific error types with user-friendly messages
      String errorMessage = "Login failed. Please try again.";

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection reset') ||
          e.toString().contains('Network is unreachable')) {
        errorMessage =
            "No internet connection. Please check your network and try again.";
      } else if (e.toString().contains('timeout') ||
          e.toString().contains('Connection timed out')) {
        errorMessage =
            "Connection timeout. Please check your internet speed and try again.";
      } else if (e.toString().contains('JWT') ||
          e.toString().contains('authentication')) {
        errorMessage = "Authentication error. Please login again.";
      }

      _showToast(errorMessage);
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
        // Update the state variable immediately
        setState(() {
          _biometricEnabled = true;
        });
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

    // Store additional data for biometrics that survives logout
    await prefs.setString('biometric_user_email', user.email ?? '');
    await prefs.setString('biometric_user_role', user.role ?? '');
    await prefs.setInt('biometric_member_id', user.memberId);

    print(
        'DEBUG: Session saved: member_id= ${user.memberId}, role= ${user.role}');
    print(
        'DEBUG: Biometrics data saved: email= ${user.email}, member_id= ${user.memberId}');
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
    } else if (userModel.role == 'Technical') {
      Navigator.push(context, MaterialPageRoute(builder: (_) {
        return TechnicalMainScreen(user: userModel);
      }));
    } else if (userModel.role == 'Sales') {
      Navigator.push(context, MaterialPageRoute(builder: (_) {
        return SalesMainScreen(user: userModel);
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
    try {
      // Check internet connection first
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        _showToast(
            "No internet connection. Please check your network and try again.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // First try to use current session data
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

      // If current session is not available, try biometrics data (for post-logout biometrics)
      final biometricMemberId = prefs.getInt('biometric_member_id');
      final biometricRole = prefs.getString('biometric_user_role');

      if (biometricMemberId != null && biometricRole != null) {
        print(
            'DEBUG: Using biometrics data for login - member_id: $biometricMemberId, role: $biometricRole');

        final userData =
            await SupabaseService.getUserByMemberId(biometricMemberId);
        if (userData != null) {
          final userModel = UserModel.fromMap(userData);

          // Restore the session data
          await _saveUserSession(userModel);

          _navigateToUserScreen(userModel);
          return;
        }
      }

      _showToast(
          'No saved session found. Please login with email and password.');
    } catch (e) {
      // Handle specific error types with user-friendly messages
      String errorMessage = "Biometric login failed. Please try again.";

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection reset') ||
          e.toString().contains('Network is unreachable')) {
        errorMessage =
            "No internet connection. Please check your network and try again.";
      } else if (e.toString().contains('timeout') ||
          e.toString().contains('Connection timed out')) {
        errorMessage =
            "Connection timeout. Please check your internet speed and try again.";
      } else if (e.toString().contains('JWT') ||
          e.toString().contains('authentication')) {
        errorMessage = "Authentication error. Please login again.";
      }

      _showToast(errorMessage);
    }
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
                    // Network status indicator
                    FutureBuilder<bool>(
                      future: _checkInternetConnection(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }

                        final hasInternet = snapshot.data ?? false;
                        if (!hasInternet) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.wifi_off,
                                    color: Colors.orange.shade700, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'No internet connection',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
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
                          backgroundColor: primaryColor,
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
                          print('DEBUG: Biometrics button pressed');
                          print(
                              'DEBUG: _biometricsAvailable: $_biometricsAvailable');
                          print('DEBUG: _biometricEnabled: $_biometricEnabled');

                          bool authenticated =
                              await _authenticateWithBiometrics();
                          if (authenticated) {
                            print('DEBUG: Biometric authentication successful');
                            await _loginWithSavedSessionOrCredentials();
                          } else {
                            print('DEBUG: Biometric authentication failed');
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

  // Clear current session but keep data for biometrics
  await prefs.remove('user_name');
  await prefs.remove('role');
  await prefs.remove('member_id');

  // Do NOT remove 'biometric_enabled' so biometric login remains enabled after logout
  // Do NOT remove session data if biometrics is enabled - this allows biometric login after logout

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => LoginPage()),
    (route) => false,
  );
}

// New function to completely clear all data (use this for app uninstall or security purposes)
void clearAllData(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  // Clear everything including biometrics
  await prefs.clear();

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => LoginPage()),
    (route) => false,
  );
}

// Function to clear only biometrics data (for user who wants to disable biometrics)
void clearBiometricsData(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  // Clear biometrics-related data
  await prefs.remove('biometric_enabled');
  await prefs.remove('biometric_user_email');
  await prefs.remove('biometric_user_role');
  await prefs.remove('biometric_member_id');

  // Navigate back to login
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => LoginPage()),
    (route) => false,
  );
}
