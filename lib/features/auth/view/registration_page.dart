import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/auth/controller/auth_provider.dart';
import 'package:taro_mobile/features/auth/repository/user_repository.dart';
import 'package:taro_mobile/features/organization/repository/organization_repository.dart';
import 'package:taro_mobile/features/home/view/home_sreen.dart' as nav;

class RegistrationScreen extends StatefulWidget {
  final String prefillPhoneNumber;
  final bool isFirstTimeLogin;

  const RegistrationScreen({
    Key? key,
    required this.prefillPhoneNumber,
    this.isFirstTimeLogin = true,
  }) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _emailCtl = TextEditingController();

  // Dependencies
  final _userRepo = UserRepository();
  final _orgRepo = OrganizationRepository();

  bool _isSubmitting = false;
  String? _selectedRole;

  final List<String> _roles = ['OrgAdmin', 'Agent', 'Viewer'];

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isFirstTimeLogin
          ? null
          : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.taroBlack, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Text(
                  "Create your account",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 40),

                // --- User Info Fields ---
                _buildInputField(
                  controller: _firstNameCtl,
                  hintText: "First Name",
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                  v == null || v.isEmpty ? 'First name required' : null,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _lastNameCtl,
                  hintText: "Last Name",
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Last name required' : null,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _emailCtl,
                  hintText: "Email",
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  v == null || !v.contains("@") ? 'Valid email required' : null,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  initialValue: widget.prefillPhoneNumber,
                  hintText: "Phone Number",
                  prefixIcon: Icons.phone_outlined,
                  enabled: false,
                ),
                const SizedBox(height: 24),

                // --- Role Selection ---
                Text(
                  "Select User Type",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.taroBlack,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: _roles
                      .map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  ))
                      .toList(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _selectedRole = val),
                  validator: (v) =>
                  v == null ? "Please select your user type" : null,
                ),
                const SizedBox(height: 40),

                // --- Register Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting || auth.isLoading
                        ? null
                        : () => _handleRegistration(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Continue",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Step 1: Handle registration logic
  Future<void> _handleRegistration(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = await _userRepo.getProfile();

      // Update user profile
      await _userRepo.updateProfile(
        firstName: _firstNameCtl.text.trim(),
        lastName: _lastNameCtl.text.trim(),
        email: _emailCtl.text.trim(),
      );

      // Handle based on role
      switch (_selectedRole) {
        case 'OrgAdmin':
          await _showCreateOrgDialog();
          break;
        case 'Agent':
          await _showJoinOrgDialog();
          break;
        case 'Viewer':
          _goToHome();
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Please select a user type"),
            backgroundColor: Colors.red,
          ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 🔹 Step 2: Create Organization (OrgAdmin flow)
  Future<void> _showCreateOrgDialog() async {
    final nameCtl = TextEditingController();
    final addressCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create Organization"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Organization Name'),
            ),
            TextField(
              controller: addressCtl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                final org = await _orgRepo.createOrganization(
                  name: nameCtl.text.trim(),
                  address: addressCtl.text.trim(),
                  maxAgents: 10,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✅ ${org.name} created successfully!'),
                    backgroundColor: Colors.green));
                _goToHome();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create org: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Step 3: Join Organization (Agent flow)
  Future<void> _showJoinOrgDialog() async {
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await _orgRepo.acceptInvite(token: tokenCtl.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Joined organization successfully!")));
                _goToHome();
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const nav.MainNavigationScreen()),
          (route) => false,
    );
  }

  Widget _buildInputField({
    TextEditingController? controller,
    String? initialValue,
    required String hintText,
    IconData? prefixIcon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey.shade600, size: 20)
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
