import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class EditInfoScreen extends StatelessWidget {
  const EditInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const int currentIndex = 4; // Assuming this screen doesn't use the nav bar, but setting for context

    return Scaffold(
      // The background color of the scaffold is set to match the app theme,
      // which appears to be AppColors.lightBackground.
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Info',
          style: TextStyle(
            color: AppColors.primary, // Dark Teal color for title
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            // Avatar with Edit Icon
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Mock profile image
                    image: const DecorationImage(
                      image: NetworkImage('https://placehold.co/120x120/799A83/1B2426?text=M'),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                ),
                // Edit Icon
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      // Handle edit avatar action
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.action, // Orange-ish action color
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: AppColors.lightText,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            // Text Fields
            const CustomTextField(
              labelText: 'Full name',
              initialValue: 'Mahi Kandari', // Typo fixed in the mock data here
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 25),
            const CustomTextField(
              labelText: 'Mobile Number',
              initialValue: '+91 96709 89000',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 25),
            const CustomTextField(
              labelText: 'Email',
              initialValue: 'mahikandari2005@gmail.com',
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 50),

            // Update Profile Button
            PrimaryButton(
              text: 'Update Profile',
              onPressed: () {
                // Handle update profile logic
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!'))
                );
              },
            ),
          ],
        ),
      ),
      // AppNavigationBar is typically not included on secondary screens like this,
      // but if needed, uncomment the line below:
      // bottomNavigationBar: const AppNavigationBar(currentIndex: currentIndex),
    );
  }
}
