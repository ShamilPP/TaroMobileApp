import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:taro_mobile/core/constants/colors.dart';
import 'package:taro_mobile/features/auth/controller/auth_provider.dart';

import '../../home/view/home_screen.dart';

class JoinOrganizationScreen extends StatefulWidget {
  final String phoneNumber;
  const JoinOrganizationScreen({super.key, required this.phoneNumber});

  @override
  State<JoinOrganizationScreen> createState() => _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState extends State<JoinOrganizationScreen> {
  final _tokenController = TextEditingController();
  bool _loading = false;

  Future<void> _join() async {
    if (_tokenController.text.isEmpty) return;

    setState(() => _loading = true);
    final success = await context.read<AuthProvider>().acceptInvite(_tokenController.text.trim());
    setState(() => _loading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Joined organization successfully!")),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid or expired invite token.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join Existing Team")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Enter your invite token below:",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: "Invitation Token",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _join,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Join Organization"),
            ),
          ],
        ),
      ),
    );
  }
}
