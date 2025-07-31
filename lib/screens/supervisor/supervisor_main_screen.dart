import 'package:exfactor/screens/login_page.dart';
import 'package:exfactor/widgets/common/custom_app_bar_with_icon.dart';
import 'package:flutter/material.dart';
import '../../widgets/common/base_layout.dart';
import 'supervisor_home.dart';
import 'supervisor_task_screen.dart';
import '../notification_screen.dart';
import '../profile.dart';
import 'package:exfactor/models/user_model.dart';

class SupervisorMainScreen extends StatefulWidget {
  final UserModel user;
  const SupervisorMainScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<SupervisorMainScreen> createState() => _SupervisorMainScreenState();
}

class _SupervisorMainScreenState extends State<SupervisorMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

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
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      const SupervisorHome(),
      const SupervisorTaskScreen(),
      const NotificationScreen(userRole: 'supervisor'),
      const ProfileScreen(userRole: 'supervisor'),
    ];
  }

  PreferredSizeWidget? _getCustomAppBar() {
    switch (_currentIndex) {
      case 1:
        return const CustomAppBarWithIcon(
            title: 'Epic Task Tracking', icon: Icons.list_alt);
      case 2:
        return const CustomAppBarWithIcon(
            title: 'Notifications', icon: Icons.notifications_active);
      case 3:
        return const CustomAppBarWithIcon(
            title: 'My Profile', icon: Icons.account_circle);
      default:
        return null;
    }
  }

  void _handleLogout() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                handleLogout(context);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
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
      onLogout: _handleLogout,
    );
  }
}
