import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import utility classes
import 'utils/app_colors.dart';

// Import all screens from the 'screens' directory
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/translation_screen.dart';
import 'screens/sign_dictionary_screen.dart';
import 'screens/sign_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_info_screen.dart';

// Import Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignSense Translator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightBackground,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          iconTheme: IconThemeData(
            color: AppColors.darkText,
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.action,
          selectionColor: AppColors.secondary,
          selectionHandleColor: AppColors.action,
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/': (context) => const HomeScreen(),
        '/translation': (context) => const TranslationScreen(),
        '/dictionary': (context) => const SignDictionaryScreen(),
        '/sign_detail': (context) => const DictionaryDetailScreen(letter: ''), // ✅ fixed
        '/profile': (context) => const ProfileScreen(),
        '/edit_info': (context) => const EditInfoScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}
