import 'package:flutter/material.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TechnicalResetPasswordScreen extends StatefulWidget {
  const TechnicalResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<TechnicalResetPasswordScreen> createState() =>
      _TechnicalResetPasswordScreenState();
}

class _TechnicalResetPasswordScreenState
    extends State<TechnicalResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  int? _memberId;

  @override
  void initState() {
    super.initState();
    _initMemberId();
  }

  Future<void> _initMemberId() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getInt('member_id');
    setState(() {
      _memberId = memberId;
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    setState(() => _loading = true);
    try {
      if (_memberId == null) {
        _showMessage('User not found.');
        return;
      }
      // Fetch user by memberId
      final user = await SupabaseService.getUserByMemberId(_memberId!);
      if (user == null) {
        _showMessage('User not found.');
        return;
      }
      final currentPassword = user['password'] ?? '';
      if (_currentPasswordController.text != currentPassword) {
        _showMessage('Current password is incorrect.');
        return;
      }
      // Update password
      await SupabaseService.updateUserProfile({
        'member_id': _memberId!,
        'password': _newPasswordController.text,
      });
      _showMessage('Password updated successfully.', success: true);
    } catch (e) {
      _showMessage('Failed to update password: \\${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMessage(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: success ? Colors.green : Colors.red),
    );
    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Password'),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter current password' : null,
              ),
              const SizedBox(height: 16),
              const Text('New Password'),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureNew ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter new password' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _handleResetPassword();
                          }
                        },
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
