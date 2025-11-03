import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/core/models/api_models.dart';
import 'package:taro_mobile/features/auth/controller/auth_provider.dart' as CustomAuth;
import 'package:taro_mobile/features/auth/repository/user_repository.dart';
import 'package:taro_mobile/features/auth/view/login_screen.dart';
import 'package:taro_mobile/features/organization/repository/organization_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  UserModel? _user;
  List<OrganizationMemberModel> _team = [];

  final _userRepo = UserRepository();
  final _orgRepo = OrganizationRepository();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = await _userRepo.getProfile();
      _user = user;

      if (user.publicSlug.isNotEmpty) {
        final members = await _orgRepo.getMembers(slug: user.publicSlug);
        setState(() {
          _team = members;
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to load profile: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  SizedBox(height: 20),
                  _buildShareProfileSection(),
                  SizedBox(height: 20),
                  _buildLinkedWebsitesSection(),
                  SizedBox(height: 20),
                  _buildTeamManagementSection(),
                  SizedBox(height: 20),
                  _buildLogoutButton(),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Lato',
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.settings, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final fullName = "${_user?.firstName ?? 'User'} ${_user?.lastName ?? ''}";
    final phone = _user?.phoneNumber ?? '+91 98765 43210';
    final email = _user?.email ?? 'user@realestate.com';
    final role = _user?.role ?? 'Team Lead';

    return Transform.translate(
      offset: Offset(0, -60),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                SizedBox(width: 16),
                
                // Name and Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Lato',
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 14,
                              color: AppColors.primaryGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              role,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Contact Info
            _buildContactRow(Icons.phone, phone),
            SizedBox(height: 12),
            _buildContactRow(Icons.email, email),
            
            SizedBox(height: 24),
            Divider(height: 1),
            SizedBox(height: 20),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('18', 'Listings'),
                _buildStatItem('42', 'Sales'),
                _buildStatItem('24', 'Leads'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Lato',
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }

  Widget _buildShareProfileSection() {
    return Transform.translate(
      offset: Offset(0, -40),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_2, color: AppColors.primaryGreen, size: 22),
                SizedBox(width: 8),
                Text(
                  'Share Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // QR Code Placeholder
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 120, color: Colors.grey[300]),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            Center(
              child: Text(
                'Scan to view profile and listings',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontFamily: 'Lato',
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Download Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Generate and download QR code
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('QR Code download coming soon!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Download QR Code',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedWebsitesSection() {
    return Transform.translate(
      offset: Offset(0, -40),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: AppColors.primaryGreen, size: 22),
                SizedBox(width: 8),
                Text(
                  'Linked Websites',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            _buildWebsiteItem('Property Portal', '99acres.com'),
            SizedBox(height: 12),
            _buildWebsiteItem('MagicBricks', 'magicbricks.com'),
            SizedBox(height: 16),
            
            // Add Website Button
            GestureDetector(
              onTap: () {
                // TODO: Show add website dialog
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '+ Add Website',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebsiteItem(String name, String url) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.apartment,
              color: AppColors.primaryGreen,
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Lato',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  url,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildTeamManagementSection() {
    return Transform.translate(
      offset: Offset(0, -40),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppColors.primaryGreen, size: 22),
                SizedBox(width: 8),
                Text(
                  'Team Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Lato',
                  ),
                ),
                Spacer(),
                Text(
                  '${_team.length} members',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Team Members
            if (_team.isNotEmpty)
              ..._team.map((member) => _buildTeamMember(member)).toList()
            else ...[
              _buildTeamMember(null, name: 'Priya Sharma', email: 'priya.sharma@realestate.com'),
              _buildTeamMember(null, name: 'Amit Patel', email: 'amit.patel@realestate.com'),
              _buildTeamMember(null, name: 'Neha Kulkarni', email: 'neha.kulkarni@realestate...', isAdmin: true),
            ],
            
            SizedBox(height: 16),
            
            // Add Member Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Show add member dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '+ Add Team Member',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMember(OrganizationMemberModel? member, {String? name, String? email, bool isAdmin = false}) {
    final displayName = member?.user.name ?? name ?? 'User';
    final displayEmail = member?.user.email ?? email ?? '';
    final memberIsAdmin = member?.role == 'OrgAdmin' || isAdmin;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Lato',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  displayEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFamily: 'Lato',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (memberIsAdmin)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Admin',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    final auth = Provider.of<CustomAuth.AuthProvider>(context, listen: false);
    
    return Transform.translate(
      offset: Offset(0, -40),
      child: OutlinedButton(
        onPressed: () async {
          await auth.signOut();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
          );
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.red[300]!, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red[600], size: 20),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
