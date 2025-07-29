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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar ??
          PreferredSize(
            preferredSize: const Size.fromHeight(120),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onProfileTap,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: (profileImage != null &&
                                profileImage!.isNotEmpty)
                            ? (profileImage!.startsWith('http')
                                ? NetworkImage(profileImage!)
                                : AssetImage(profileImage!) as ImageProvider)
                            : const AssetImage('assets/images/it-avatar.webp'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onIndexChanged,
        selectedItemColor: Color.fromARGB(255, 255, 255, 255),
        unselectedItemColor: Colors.white60,
        backgroundColor: Color(0xFF002055),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: navigationItems,
      ),
    );
  }
}
