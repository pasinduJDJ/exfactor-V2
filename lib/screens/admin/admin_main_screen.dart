import 'package:exfactor/models/user_model.dart';
import 'package:exfactor/screens/admin/admin_manage_project&TaskScreen.dart';
import 'package:exfactor/screens/admin/admin_manage_users.dart';
import 'package:exfactor/screens/admin/admin_sale_screen.dart';
import 'package:exfactor/screens/login_page.dart';
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
    const AdminSaleScreen(),
    const AdminProjectManage(),
    const AdminNotificationScreen(),
    const MangeUsers(),
  ];

  // Method to handle navigation between tabs
  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Updated screens list with navigation callback
  List<Widget> get _screensWithNavigation => [
        AdminHome(onNavigateToTab: _navigateToTab),
        const AdminSaleScreen(),
        const AdminProjectManage(),
        const AdminNotificationScreen(),
        const MangeUsers(),
      ];

  final List<BottomNavigationBarItem> _navigationItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.track_changes_outlined),
      activeIcon: Icon(Icons.track_changes),
      label: 'Sales',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.assignment_outlined),
      activeIcon: Icon(Icons.assignment),
      label: 'Tasks',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.event_outlined),
      activeIcon: Icon(Icons.event),
      label: 'Events',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.group_add_outlined),
      activeIcon: Icon(Icons.group_add),
      label: 'Team',
    ),
  ];

  PreferredSizeWidget? _getCustomAppBar() {
    switch (_currentIndex) {
      case 1:
        return const CustomAppBarWithIcon(
            title: 'Sales', icon: Icons.track_changes);
      case 2:
        return const CustomAppBarWithIcon(
            title: 'Projects', icon: Icons.list_alt);
      case 3:
        return const CustomAppBarWithIcon(
            title: 'Events', icon: Icons.notifications_active);
      case 4:
        return const CustomAppBarWithIcon(
            title: 'Members', icon: Icons.account_circle);
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
      onProfileTap: () {
        // Handle profile tap - you can navigate to profile screen
        print('Profile tapped');
      },
      body: _screensWithNavigation[_currentIndex],
      currentIndex: _currentIndex,
      onIndexChanged: (index) => setState(() => _currentIndex = index),
      navigationItems: _navigationItems,
      customAppBar: _getCustomAppBar(),
      onLogout: _handleLogout,
    );
  }
}
