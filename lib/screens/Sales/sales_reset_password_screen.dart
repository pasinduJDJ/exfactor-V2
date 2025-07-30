import 'package:flutter/material.dart';

class SalesResetPasswordScreen extends StatefulWidget {
  const SalesResetPasswordScreen({super.key});

  @override
  State<SalesResetPasswordScreen> createState() =>
      _SalesResetPasswordScreenState();
}

class _SalesResetPasswordScreenState extends State<SalesResetPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: const Center(
        child: Text(
          'Sales Reset Password Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
