import 'package:flutter/material.dart';
import 'package:exfactor/screens/admin/admin_single_profile.dart';

class UserCard {
  static Widget buildUserGridCard(List<Map<String, String>> users,
      {Function(String)? onUserRemoved}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(), // Important if inside Column
        itemCount: users.length,
        itemBuilder: (context, i) {
          final u = users[i];
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 6,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            u['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            u['email'] ?? '',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            u['role'] ?? '',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdminSingleProfileScreen(
                                          userEmail: u['email'] ?? ''),
                                ),
                              );

                              // Handle the result
                              if (result == 'user_removed' &&
                                  onUserRemoved != null) {
                                onUserRemoved('user_removed');
                              }
                            },
                            child: const Text(
                              'see more ..',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Avatar
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          (u['avatar'] != null && u['avatar']!.isNotEmpty)
                              ? NetworkImage(u['avatar']!)
                              : const AssetImage('assets/images/it-avatar.webp')
                                  as ImageProvider,
                      child: (u['avatar'] == null || u['avatar']!.isEmpty)
                          ? const Icon(Icons.person_outline, size: 30)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
