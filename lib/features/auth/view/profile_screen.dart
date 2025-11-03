import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final TextEditingController _firstNameCtl = TextEditingController();
  final TextEditingController _lastNameCtl = TextEditingController();
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _phoneCtl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  UserModel? _user;
  OrganizationModel? _org;
  List<OrganizationMemberModel> _team = [];
  List<OrganizationInviteModel> _invites = [];
  Map<String, dynamic>? _orgStats;

  final _userRepo = UserRepository();
  final _orgRepo = OrganizationRepository();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  /// ✅ Load user and organization info
  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = await _userRepo.getProfile();
      debugPrint("👤 USER: ${user.toJson()}");

      _firstNameCtl.text = user.firstName;
      _lastNameCtl.text = user.lastName;
      _emailCtl.text = user.email ?? '';
      _phoneCtl.text = user.phoneNumber.replaceAll('+91', '');

      _user = user;

      if (user.publicSlug.isNotEmpty) {
        final org = await _orgRepo.getOrganization(slug: user.publicSlug);
        final members = await _orgRepo.getMembers(slug: user.publicSlug);
        final invites = await _orgRepo.getInvites(slug: user.publicSlug);
        final stats = await _orgRepo.getOrganizationStats(slug: user.publicSlug);

        setState(() {
          _org = org;
          _team = members;
          _invites = invites;
          _orgStats = stats;
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to load profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// ✅ Update user info
  Future<void> _updateProfile() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await _userRepo.updateProfile(
        firstName: _firstNameCtl.text.trim(),
        lastName: _lastNameCtl.text.trim(),
        email: _emailCtl.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
      await _loadProfile();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      setState(() => _saving = false);
    }
  }

  /// ✅ Join org via token
  Future<void> _joinOrganization() async {
    final tokenCtl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Join Organization"),
        content: TextField(
          controller: tokenCtl,
          decoration: const InputDecoration(labelText: 'Enter Invite Token'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () async {
              try {
                await _orgRepo.acceptInvite(token: tokenCtl.text.trim());
                Navigator.pop(context);
                await _loadProfile();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Joined organization successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  /// ✅ Invite member
  Future<void> _inviteMember() async {
    final phoneCtl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Invite Member'),
        content: TextField(
          controller: phoneCtl,
          decoration: const InputDecoration(labelText: 'Phone (+91...)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () async {
              try {
                await _orgRepo.inviteMember(
                  slug: _org!.slug,
                  phone: phoneCtl.text.trim(),
                );
                Navigator.pop(context);
                await _loadProfile();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite sent successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  /// ✅ Delete member
  Future<void> _removeMember(String uid) async {
    final confirmed = await _confirmDialog("Remove Member", "Remove this team member?");
    if (!confirmed) return;
    try {
      await _orgRepo.deleteMember(slug: _org!.slug, uid: uid);
      await _loadProfile();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to remove member: $e")));
    }
  }

  /// ✅ Delete invite
  Future<void> _deleteInvite(String phone) async {
    final confirmed = await _confirmDialog("Delete Invite", "Delete this pending invite?");
    if (!confirmed) return;
    try {
      await _orgRepo.deleteInvite(slug: _org!.slug, phone: phone);
      await _loadProfile();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to delete invite: $e")));
    }
  }

  Future<bool> _confirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<CustomAuth.AuthProvider>(context);
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryGreen,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildProfileForm(),
            const SizedBox(height: 20),
            if (_org != null) _buildOrgCard(),
            if (_orgStats != null) _buildStatsCard(),
            if (_team.isNotEmpty) _buildTeamCard(),
            if (_invites.isNotEmpty) _buildInvitesCard(),
            if (_org == null) _buildJoinOrgButton(),
            const SizedBox(height: 30),
            _buildLogoutButton(auth),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ListTile(
      leading: const CircleAvatar(
        radius: 30,
        backgroundColor: AppColors.primaryGreen,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        "${_user?.firstName ?? ''} ${_user?.lastName ?? ''}",
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(_user?.email ?? ''),
      trailing: Text(
        _user?.role ?? '',
        style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12),
      ),
    ),
  );

  Widget _buildProfileForm() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _inputField("First Name", _firstNameCtl),
        const SizedBox(height: 12),
        _inputField("Last Name", _lastNameCtl),
        const SizedBox(height: 12),
        _inputField("Email", _emailCtl, type: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _inputField("Phone", _phoneCtl, enabled: false),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saving ? null : _updateProfile,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              minimumSize: const Size(double.infinity, 45)),
          child: _saving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Save Changes"),
        ),
      ]),
    ),
  );

  Widget _inputField(String label, TextEditingController ctl,
      {bool enabled = true, TextInputType? type}) =>
      TextField(
        controller: ctl,
        keyboardType: type,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Widget _buildOrgCard() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.apartment, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          const Text("Organization",
              style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Text("Name: ${_org?.name ?? '-'}"),
        Text("Plan: ${_org?.plan ?? '-'}"),
        Text("Agents: ${_org?.agentCount ?? 0}"),
        Text("Status: ${_org?.status ?? '-'}"),
      ]),
    ),
  );

  Widget _buildStatsCard() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Organization Statistics",
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_orgStats != null)
          ..._orgStats!.entries.map(
                (e) => Text("${e.key}: ${e.value}"),
          ),
      ]),
    ),
  );

  Widget _buildTeamCard() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(
          children: [
            const Text("Team Members",
                style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            ElevatedButton(
              onPressed: _inviteMember,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.all(8),
              ),
              child:
              const Text("+ Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final m in _team)
          ListTile(
            title: Text(m.user.name),
            subtitle: Text(m.user.email ?? ''),
            trailing: m.role == 'OrgAdmin'
                ? const Text("Admin", style: TextStyle(color: Colors.grey))
                : IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent),
              onPressed: () => _removeMember(m.uid),
            ),
          ),
      ]),
    ),
  );

  Widget _buildInvitesCard() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const Text("Pending Invites",
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_invites.isEmpty)
          const Text("No invites found",
              style: TextStyle(color: Colors.grey)),
        for (final i in _invites)
          ListTile(
            title: Text(i.phone),
            subtitle: Text('Role: ${i.role}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteInvite(i.phone),
            ),
          ),
      ]),
    ),
  );

  Widget _buildJoinOrgButton() => Center(
    child: ElevatedButton(
      onPressed: _joinOrganization,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text("Join an Organization"),
    ),
  );

  Widget _buildLogoutButton(CustomAuth.AuthProvider auth) => OutlinedButton(
    onPressed: () async {
      await auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) =>  LoginScreen()),
            (route) => false,
      );
    },
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    child: const Text("Log Out", style: TextStyle(color: Colors.black)),
  );
}
