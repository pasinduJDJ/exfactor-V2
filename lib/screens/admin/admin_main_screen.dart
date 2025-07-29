import 'package:exfactor/models/user_model.dart';
import 'package:exfactor/screens/admin/admin_manage_project&TaskScreen.dart';
import 'package:exfactor/screens/admin/admin_manage_users.dart';
import 'package:flutter/material.dart';
import '../../widgets/common/base_layout.dart';
import 'admin_home.dart';
import 'admin_notification_screen.dart';
import 'package:exfactor/widgets/common/custom_app_bar_with_icon.dart';

class AdminMainScreen extends StatefulWidget {
  final UserModel user;
  const AdminMainScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminHome(),
    const AdminProjectManage(),
    const AdminNotificationScreen(),
    const MangeUsers(),
  ];

  final List<BottomNavigationBarItem> _navigationItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.checklist),
      label: 'Tasks',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.notifications),
      label: 'Notifications',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.supervised_user_circle),
      label: 'Manage',
    ),
  ];

  PreferredSizeWidget? _getCustomAppBar() {
    switch (_currentIndex) {
      case 1:
        return const CustomAppBarWithIcon(
            title: 'Manage Projects', icon: Icons.list_alt);
      case 2:
        return const CustomAppBarWithIcon(
            title: 'Manage Notifications', icon: Icons.notifications_active);
      case 3:
        return const CustomAppBarWithIcon(
            title: 'Manage Users', icon: Icons.account_circle);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: "${widget.user.firstName ?? ''}",
      subtitle: "${widget.user.position ?? ''}",
      profileImage: "${widget.user.profileImage ?? ''}",
      onProfileTap: () {},
      body: _screens[_currentIndex],
      currentIndex: _currentIndex,
      onIndexChanged: (index) => setState(() => _currentIndex = index),
      navigationItems: _navigationItems,
      customAppBar: _getCustomAppBar(),
    );
  }
}
