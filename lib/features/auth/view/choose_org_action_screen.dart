import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/core/models/api_models.dart';
import 'package:taro_mobile/features/organization/repository/organization_repository.dart';
import 'package:taro_mobile/features/home/view/home_sreen.dart' as nav;
import 'create_org_screen.dart';
import 'join_org_screen.dart';

class ChooseOrgActionScreen extends StatefulWidget {
  final String phoneNumber;
  const ChooseOrgActionScreen({super.key, required this.phoneNumber});

  @override
  State<ChooseOrgActionScreen> createState() => _ChooseOrgActionScreenState();
}

class _ChooseOrgActionScreenState extends State<ChooseOrgActionScreen> {
  final OrganizationRepository _orgRepo = OrganizationRepository();

  bool _isLoading = true;
  List<OrganizationInviteModel> _pendingInvites = [];

  @override
  void initState() {
    super.initState();
    _loadPendingInvites();
  }

  Future<void> _loadPendingInvites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invites = await _orgRepo.getMyInvites();
      setState(() {
        // Filter invites that are not used and are active
        _pendingInvites = invites.where((invite) => !invite.used && invite.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Silently fail - invites are optional
    }
  }

  Future<void> _acceptInvite(OrganizationInviteModel invite) async {
    try {
      setState(() => _isLoading = true);

      // Get invite token
      if (invite.token.isEmpty) {
        throw Exception('Invalid invite token');
      }

      await _orgRepo.acceptInvite(token: invite.token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully joined organization!'), backgroundColor: AppColors.primaryGreen));

        // Navigate to home
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => nav.MainNavigationScreen()), (route) => false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to accept invite: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 32),

              // Pending Invites Section
              if (_isLoading)
                Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_pendingInvites.isNotEmpty)
                _buildPendingInvitesSection(),

              if (!_isLoading) const SizedBox(height: 32),

              // Action Buttons
              if (!_isLoading) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome! 👋', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textColor)),
        const SizedBox(height: 8),
        Text('Get started by joining or creating an organization', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPendingInvitesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mail_outline, color: AppColors.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text('Pending Invitations', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textColor)),
          ],
        ),
        const SizedBox(height: 16),
        ..._pendingInvites.map((invite) => _buildInviteCard(invite)),
      ],
    );
  }

  Widget _buildInviteCard(OrganizationInviteModel invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.business, color: AppColors.primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Organization Invitation', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textColor)),
                    const SizedBox(height: 4),
                    Text('Role: ${invite.role}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : () => _acceptInvite(invite),
              child:
                  _isLoading
                      ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text('Accept Invitation', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_pendingInvites.isEmpty) Text('No pending invitations', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
        if (_pendingInvites.isEmpty) const SizedBox(height: 24),
        Text('Or choose an action:', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textColor)),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.add_business,
          title: 'Create New Organization',
          subtitle: 'Start your own team and invite members',
          color: AppColors.primaryGreen,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateOrganizationScreen(phoneNumber: widget.phoneNumber))),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.group_add,
          title: 'Join Existing Team',
          subtitle: 'Enter an invitation token to join',
          color: AppColors.primaryDarkBlue,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JoinOrganizationScreen(phoneNumber: widget.phoneNumber))),
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textColor)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
