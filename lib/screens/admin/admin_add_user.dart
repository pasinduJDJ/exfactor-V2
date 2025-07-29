import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';
import '../../services/superbase_service.dart';
import '../../utils/validators.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memberIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roleController = TextEditingController();
  final _positionController = TextEditingController();
  bool _isLoading = false;
  String? _selectedRole;
  final List<String> _roles = ['Technician', 'Sales', 'Supervisor', 'Admin'];
  bool _obscurePassword = true; // Added for password visibility

  @override
  void dispose() {
    _memberIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Validate all required fields
    if (_memberIdController.text.trim().isEmpty ||
        _firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _selectedRole == null ||
        _positionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    // Validate Member ID
    final memberId = int.tryParse(_memberIdController.text.trim());
    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member ID must be a valid number.')),
      );
      return;
    }

    // Validate email format
    final emailValidation = validateEmail(_emailController.text.trim());
    if (emailValidation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailValidation)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if email already exists in database
      final existingUser =
          await SupabaseService.getUserByEmail(_emailController.text.trim());
      if (existingUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User already registered with this email address.'),
            backgroundColor: Colors.red,
          ),
        );
        // Navigate back to admin manage users screen
        Navigator.of(context).pop('user_added');
        return;
      }

      // If email doesn't exist, create the user
      final userData = {
        'member_id': memberId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'role': _selectedRole,
        'position': _positionController.text.trim(),
      };

      await SupabaseService.insertUser(userData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User registered successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop('user_added');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KbgColor,
      appBar: AppBar(
        title: const Text("Add New Team Member"),
        backgroundColor: kPrimaryColor,
        foregroundColor: kWhite,
        elevation: 1,
        iconTheme: const IconThemeData(color: kWhite),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text("Enter Employee Register Number"),
              TextFormField(
                controller: _memberIdController,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  // border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              const Text("Enter First Name"),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text("Enter Last Name"),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text("Enter Email Address"),
              TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    // border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail),
              const SizedBox(height: 20),
              const Text("Select Role"),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _roles
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedRole = val),
                validator: (val) => val == null ? 'Please select a role' : null,
              ),
              const SizedBox(height: 20),
              const Text("Enter Position"),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text("Enter Password"),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  // border: OutlineInputBorder(),
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
              const SizedBox(height: 30),
              CustomButton(
                text: 'Create User',
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                backgroundColor: kPrimaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
