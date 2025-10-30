import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/auth/controller/auth_provider.dart'
    as CustomAuth;
import 'package:taro_mobile/features/auth/view/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _secondNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _reraController = TextEditingController();
  static const platform = MethodChannel('com.taro.mobileapp/call_detection');

  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // Contact popup settings
  bool _showPopupForContacts = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadContactPopupSettings();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _reraController.dispose();
    super.dispose();
  }

  String getTrimmedPhoneNumber() {
    String text = _phoneController.text.trim();
    return text.startsWith('+91') ? text.substring(3).trim() : text;
  }

  Future<void> _loadContactPopupSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _showPopupForContacts =
            prefs.getBool('show_popup_for_contacts') ?? false;
      });
      print(
        'Contact popup settings loaded: showPopupForContacts=$_showPopupForContacts',
      );
    } catch (e) {
      print('Error loading contact popup settings: $e');
    }
  }

  Future<void> _saveContactPopupSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_popup_for_contacts', _showPopupForContacts);

      // Also save to method channel to sync with native Android immediately
      platform.invokeMethod('updatePopupSettings', {
        'showPopupForContacts': _showPopupForContacts,
      });

      print(
        'Contact popup settings saved: showPopupForContacts=$_showPopupForContacts',
      );
    } catch (e) {
      print('Error saving contact popup settings: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _firstNameController.text = _userData?['firstName'] ?? '';
            _secondNameController.text = _userData?['lastName'] ?? '';
            _emailController.text = _userData?['email'] ?? user.email ?? '';
            _phoneController.text = (_userData?['phoneNumber'] ?? '')
                .toString()
                .trim()
                .replaceFirst(RegExp(r'^\+?91'), '');
            _reraController.text = _userData?['reraNumber'] ?? '';

            _isLoading = false;
          });
        } else {
          final userData = {
            'firstName': '',
            'lastName': '',
            'email': user.email ?? '',
            'phone': '',
            'reraNumber': '',
            'createdAt': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(userData);

          setState(() {
            _userData = userData;
            _emailController.text = user.email ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'firstName': _firstNameController.text.trim(),
              'lastName': _secondNameController.text.trim(),
              'email': _emailController.text.trim(),
              'phoneNumber': _phoneController.text.trim(),
              'reraNumber': _reraController.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Save popup setting to SharedPreferences only
        await _saveContactPopupSettings();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xff91C94F),
          ),
        );

        await _loadUserData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getInitials() {
    final firstName = _firstNameController.text.trim();
    final lastName = _secondNameController.text.trim();

    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }

    return initials.isEmpty ? 'U' : initials;
  }

  String _getFullName() {
    final firstName = _firstNameController.text.trim();
    final lastName = _secondNameController.text.trim();
    return '$firstName $lastName'.trim();
  }

  Widget _buildContactPopupSettings() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Call Popup Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Toggle for contact popup
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  _showPopupForContacts
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    _showPopupForContacts
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Show Popup for Added Contacts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Show lead information popup for contacts saved in your phone',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _showPopupForContacts,
                  onChanged: (value) {
                    setState(() {
                      _showPopupForContacts = value;
                    });
                    // Save the preference immediately when changed
                    _saveContactPopupSettings();
                  },
                  activeColor: AppColors.primaryGreen,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Info text
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Popups will always show for unknown numbers. This setting only affects saved contacts.',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomAuth.AuthProvider>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xff91C94F),
                      child: Text(
                        _getInitials(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  _getFullName().isEmpty ? 'User Name' : _getFullName(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),

              Center(
                child: Text(
                  _emailController.text.isEmpty
                      ? 'user@email.com'
                      : _emailController.text,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),

              const SizedBox(height: 30),

              ProfileTextField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.edit,
              ),

              const SizedBox(height: 16),

              ProfileTextField(
                controller: _secondNameController,
                label: 'Last Name',
                icon: Icons.edit,
              ),

              const SizedBox(height: 16),

              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    width: 80,
                    height: 55,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('+91', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProfileTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ProfileTextField(controller: _reraController, label: 'RERA NO:'),

              // Contact Popup Settings Section
              _buildContactPopupSettings(),

              const SizedBox(height: 30),

              SizedBox(
                width: 300,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: 150,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Log Out'),
                          content: const Text(
                            'Are you sure you want to log out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                                authProvider.signOut();
                              },
                              child: const Text('Log Out'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1E4C70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;

  const ProfileTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          suffixIcon:
              icon != null
                  ? Icon(icon, size: 20, color: Colors.grey[600])
                  : null,
        ),
      ),
    );
  }
}
