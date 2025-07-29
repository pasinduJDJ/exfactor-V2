import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';

class AdminTaskScreen extends StatelessWidget {
  const AdminTaskScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KbgColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Task Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Create New Task',
              onPressed: () {
                // TODO: Implement task creation
              },
            ),
          ],
        ),
      ),
    );
  }
}
