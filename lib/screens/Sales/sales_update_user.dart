import 'package:flutter/material.dart';
import 'package:exfactor/models/user_model.dart';

class SalesUpdateUser extends StatefulWidget {
  final UserModel user;
  const SalesUpdateUser({Key? key, required this.user}) : super(key: key);

  @override
  State<SalesUpdateUser> createState() => _SalesUpdateUserState();
}

class _SalesUpdateUserState extends State<SalesUpdateUser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
      ),
      body: const Center(
        child: Text(
          'Sales Update User Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
