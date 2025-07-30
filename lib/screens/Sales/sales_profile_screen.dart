import 'package:exfactor/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:exfactor/screens/login_page.dart';
import 'package:exfactor/utils/colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../services/superbase_service.dart';
import 'sales_update_user.dart';
import 'sales_reset_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesProfileScreen extends StatefulWidget {
  const SalesProfileScreen({Key? key}) : super(key: key);

  @override
  State<SalesProfileScreen> createState() => _SalesProfileScreenState();
}

class _SalesProfileScreenState extends State<SalesProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  String? supervisorName;
  int? _memberId;

  @override
  void initState() {
    super.initState();
    _initMemberIdAndFetchUser();
  }

  Future<void> _initMemberIdAndFetchUser() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getInt('member_id');
    if (memberId != null) {
      setState(() {
        _memberId = memberId;
      });
      await _fetchUser(memberId);
      await _fetchSupervisorName();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchUser(int memberId) async {
    setState(() => _loading = true);
    final data = await SupabaseService.getUserByMemberId(memberId);
    if (data != null) {
      setState(() {
        _user = UserModel.fromMap(data);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchSupervisorName() async {
    // TODO: Implement supervisor fetching if needed
    setState(() {
      supervisorName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Header
            _buildProfileHeader(),

            const SizedBox(height: 20),

            // Profile Details
            _buildProfileDetails(),

            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child:
                _user?.profileImage != null && _user!.profileImage!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _user!.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey[600],
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey[600],
                      ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 8),

          // Position
          Text(
            _user?.position ?? 'Sales Representative',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Email', _user?.email ?? ''),
          _buildDetailRow('Phone', _user?.mobile ?? ''),
          _buildDetailRow('Role', _user?.role ?? ''),
          if (supervisorName != null)
            _buildDetailRow('Supervisor', supervisorName!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Update Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SalesUpdateUser(user: _user!),
              ),
            );
          },
          backgroundColor: kPrimaryColor,
          width: double.infinity,
          height: 48,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Reset Password',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SalesResetPasswordScreen(),
              ),
            );
          },
          backgroundColor: Colors.orange,
          width: double.infinity,
          height: 48,
        ),
      ],
    );
  }
}
