import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/home_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'services/health_prediction_service.dart';
import 'services/supabase_service.dart';
import 'services/location_service.dart';
import 'services/onboarding_service.dart';
import 'theme/app_theme.dart';

void main() async {
  print('=== MAIN FUNCTION START ===');
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('📡 Initializing Supabase...');
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://pcqfdxgajkojuffiiykt.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjcWZkeGdhamtvanVmZmlpeWt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4NzYyMzYsImV4cCI6MjA3NjQ1MjIzNn0.lf0e9v-qyOXPa_GQPsBRbyMH_VfcNJS2oash49RD_ik',
    );
    print('✅ Supabase initialized successfully');

    print('📡 Initializing HealthPredictionService...');
    // Initialize services
    await HealthPredictionService.instance.initialize();
    print('✅ HealthPredictionService initialized');

    print('📡 Initializing LocationService...');
    await LocationService.instance.initialize();
    print('✅ LocationService initialized');

    print('📡 Initializing OnboardingService...');
    await OnboardingService.instance.initialize();
    print('✅ OnboardingService initialized');

    print('📡 Initializing SupabaseService...');
    await SupabaseService.instance.initialize();
    print('✅ SupabaseService initialized');

    print('✅ All services initialized successfully');
  } catch (e) {
    print('❌ Error initializing services: $e');
    print('❌ Error type: ${e.runtimeType}');
    print('❌ Stack trace: ${StackTrace.current}');
    // Continue anyway - services will handle errors gracefully
  }

  print('📱 Starting TaimakoApp...');
  runApp(const TaimakoApp());
  print('=== MAIN FUNCTION END ===');
}

class TaimakoApp extends StatelessWidget {
  const TaimakoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
                create: (_) => HealthPredictionService.instance),
            ChangeNotifierProvider(create: (_) => SupabaseService.instance),
            ChangeNotifierProvider(create: (_) => LocationService.instance),
            ChangeNotifierProvider(create: (_) => OnboardingService.instance),
          ],
          child: MaterialApp(
            title: 'Taimako - AI Health Assistant',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: const AppWrapper(),
            routes: {
              '/profile-setup': (context) => const ProfileSetupScreen(),
              '/home': (context) => const HomeScreen(),
            },
          ),
        );
      },
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print('=== APP WRAPPER BUILD ===');
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        print('📡 Auth state change: ${snapshot.connectionState}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ Auth state waiting, showing SplashScreen');
          return const SplashScreen();
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;
        print('📡 Session exists: ${session != null}');
        print('📡 User ID: ${session?.user.id}');

        if (session != null) {
          print('✅ User authenticated, showing HomeScreen');
          return const HomeScreen();
        } else {
          print('❌ User not authenticated, checking onboarding');
          return Consumer<OnboardingService>(
            builder: (context, onboardingService, child) {
              final shouldShowOnboarding =
                  onboardingService.shouldShowOnboarding();
              print('📡 Should show onboarding: $shouldShowOnboarding');

              if (shouldShowOnboarding) {
                print('📱 Showing OnboardingScreen');
                return const OnboardingScreen();
              } else {
                print('📱 Showing LoginScreen');
                return const LoginScreen();
              }
            },
          );
        }
      },
    );
  }
}
