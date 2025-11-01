// lib/screens/auth/signup_screen.dart

import 'package:flutter/material.dart';
// Import for debugPrint
import '../../utils/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../home_screen.dart'; // Target screen after successful signup
// Note: This import may still be unused, but kept if other files use it.

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  // Replaced print() with debugPrint()
  void _socialLogin(String platform) {
    debugPrint('Attempting signup with $platform'); // ✅ FIX: Replaced print()
  }

  // ✅ FIX: Renamed _SocialLoginIcon to SocialLoginIcon (PascalCase for a public widget)
  Widget SocialLoginIcon({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.primary, // Used primary color for better contrast
          size: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // ✨ IMPROVEMENT: Set background color
      appBar: AppBar(
        title: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Simple Title)
            const Text(
              'Create a New Account', // Slightly modified title
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const SizedBox(height: 32),

            // Form Fields (✅ FIX: Added initialValue to satisfy TextFormField requirement)
            const CustomTextField(
              labelText: 'Full name',
              initialValue: '', // 🐞 FIX: Added required parameter
            ),
            const SizedBox(height: 16),
            const CustomTextField(
              labelText: 'Mobile Number',
              keyboardType: TextInputType.phone,
              initialValue: '', // 🐞 FIX: Added required parameter
            ),
            const SizedBox(height: 16),
            const CustomTextField(
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              initialValue: '', // 🐞 FIX: Added required parameter
            ),
            const SizedBox(height: 16),
            const CustomTextField(
              labelText: 'Password',
              isPassword: true,
              initialValue: '', // 🐞 FIX: Added required parameter
            ),
            const SizedBox(height: 24),

            // Terms and Privacy Text
            Center(
              child: Text(
                'By continuing you agree to Terms of Use and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),

            // Sign Up Button
            PrimaryButton(
              text: 'Sign Up',
              onPressed: () {
                // TODO: Implement signup logic and navigate to HomeScreen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
            ),
            const SizedBox(height: 24),

            // Social Login Divider
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.grey)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'or sign up with',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),

            // Social Login Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ FIX: Renamed _SocialLoginIcon to SocialLoginIcon
                SocialLoginIcon(
                  icon: Icons.facebook,
                  onTap: () => _socialLogin('Facebook'),
                ),
                const SizedBox(width: 32),
                SocialLoginIcon( // ✅ FIX: Renamed _SocialLoginIcon to SocialLoginIcon
                  icon: Icons.language,
                  onTap: () => _socialLogin('Google'),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Already have an account link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? ",
                    style: TextStyle(fontSize: 16, color: AppColors.darkText)),
                GestureDetector(
                  onTap: () {
                    // Pop to remove the current screen and reveal the LoginScreen
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
