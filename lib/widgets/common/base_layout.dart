import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';

class BaseLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? profileImage;
  final VoidCallback? onProfileTap;
  final Widget body;
  final int currentIndex;
  final Function(int) onIndexChanged;
  final List<BottomNavigationBarItem> navigationItems;
  final PreferredSizeWidget? customAppBar;
  final VoidCallback? onLogout; // Add logout callback

  BaseLayout({
    Key? key,
    required this.title,
    required this.subtitle,
    this.profileImage,
    this.onProfileTap,
    required this.body,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.navigationItems,
    this.customAppBar,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      appBar: customAppBar ??
          PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                  child: AppBar(
                title: const Text(
                  "EXFACTOR",
                  style: TextStyle(
                    letterSpacing: 2,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: IconButton(
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
                centerTitle: true,
                toolbarHeight: 90,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
              )),
            ),
          ),
      body: body,
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: primaryColor,
          // borderRadius: BorderRadius.only(
          //   topLeft: Radius.circular(20),
          //   topRight: Radius.circular(20),
          // ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onIndexChanged,
          selectedItemColor: kWhite,
          unselectedItemColor: Color.fromARGB(153, 255, 255, 255),
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation:
              0, // Remove default elevation since we're using custom container
          items: navigationItems,
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return SafeArea(
        child: Drawer(
      child: Column(
        children: [
          // Profile Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Profile Image
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/it-avatar.webp'),
                  // (profileImage != null && profileImage!.isNotEmpty)
                  //     ? (profileImage!.startsWith('http')
                  //         ? NetworkImage(profileImage!)
                  //         : AssetImage(profileImage!) as ImageProvider)
                  //     : const AssetImage('assets/images/it-avatar.webp'),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kWhite,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kWhite,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 20),

                // // Profile Option
                // ListTile(
                //   leading:
                //       const Icon(Icons.person_outline, color: primaryColor),
                //   title: const Text('Profile'),
                //   onTap: () {
                //     Navigator.pop(context); // Close drawer
                //     onProfileTap?.call();
                //   },
                // ),

                // const Divider(),

                // Settings Option
                ListTile(
                  leading:
                      const Icon(Icons.settings_outlined, color: primaryColor),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add settings navigation logic here
                  },
                ),

                const Divider(),

                // Help Option
                ListTile(
                  leading: const Icon(Icons.help_outline, color: primaryColor),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add help navigation logic here
                  },
                ),

                const Divider(),

                // About Option
                ListTile(
                  leading: const Icon(Icons.info_outline, color: primaryColor),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add about navigation logic here
                  },
                ),
              ],
            ),
          ),

          // Company Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Image.asset(
              'assets/images/Exfactor.png',
              height: 50,
            ),
            // Container(
            //   height: 60,
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(12),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black.withOpacity(0.1),
            //         blurRadius: 8,
            //         offset: const Offset(0, 2),
            //       ),
            //     ],
            //   ),
            //   child: Padding(
            //     padding: const EdgeInsets.all(12.0),
            //     child: Image.asset(
            //       'assets/images/Exfactor.png',
            //       fit: BoxFit.contain,
            //     ),
            //   ),
            // ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close drawer
                  onLogout?.call();
                },
                icon: const Icon(Icons.logout, color: kWhite),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: kWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardRed,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
