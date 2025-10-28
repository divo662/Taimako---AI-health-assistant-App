import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../services/onboarding_service.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Check your\nsymptoms and get\nhealth insights\ninstantly",
      subtitle: "",
      description: "",
      icon: Icons.medical_services,
      isIntroPage: true,
    ),
    OnboardingPage(
      title: "Welcome To\nTaimako",
      subtitle: "Check your symptoms and get health insights instantly.",
      description:
          "Taimako helps you understand possible conditions from your symptoms. It's not a substitute for a doctor, so always seek professional advice.",
      icon: Icons.medical_services,
    ),
    OnboardingPage(
      title: "AI-Powered\nHealth Assistant",
      subtitle:
          "Get instant health insights powered by advanced AI technology.",
      description:
          "Our AI analyzes your symptoms using a comprehensive Nigerian medical database to provide accurate health predictions.",
      icon: Icons.psychology,
    ),
    OnboardingPage(
      title: "Location-Based\nPredictions",
      subtitle: "Get predictions tailored to your location and environment.",
      description:
          "We consider your state, climate, and local health patterns to provide more accurate and relevant health insights.",
      icon: Icons.location_on,
    ),
    OnboardingPage(
      title: "Blockchain\nVerification",
      subtitle: "Your health data is securely verified on the blockchain.",
      description:
          "Every prediction is logged on Hedera blockchain for transparency, security, and data integrity.",
      icon: Icons.security,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final onboardingService =
        Provider.of<OnboardingService>(context, listen: false);
    await onboardingService.completeOnboarding();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2E), // Dark gray background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: _previousPage,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),

                  Text(
                    'Onboarding',
                    style: TextStyle(
                      color: const Color(0xFF2C2C2E),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  // Skip button
                  if (_currentPage < _pages.length - 1)
                    GestureDetector(
                      onTap: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Bottom Section
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: _currentPage == index ? 24.w : 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF00D4AA) // Teal color
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA), // Teal color
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),

                  // Terms and Conditions
                  if (_currentPage == _pages.length - 1) ...[
                    SizedBox(height: 16.h),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.6),
                          fontFamily: 'Poppins',
                        ),
                        children: const [
                          TextSpan(text: 'By continuing, you agree to our '),
                          TextSpan(
                            text: 'terms',
                            style: TextStyle(
                              color: Color(0xFF00D4AA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'conditions',
                            style: TextStyle(
                              color: Color(0xFF00D4AA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    if (page.isIntroPage) {
      return _buildIntroPage();
    } else {
      return _buildRegularPage(page);
    }
  }

  Widget _buildIntroPage() {
    return Container(
      margin: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF00D4AA), // Teal color
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Image.asset(
                    'assets/images/app logo.png',
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                "Check your\nsymptoms and get\nhealth insights\ninstantly",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegularPage(OnboardingPage page) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              page.icon,
              size: 40.sp,
              color: const Color(0xFF00D4AA),
            ),
          ),

          SizedBox(height: 32.h),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C2C2E),
              fontFamily: 'Poppins',
              height: 1.2,
            ),
          ),

          SizedBox(height: 16.h),

          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),

          SizedBox(height: 24.h),

          // Description Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 20.sp,
                    color: const Color(0xFF00D4AA),
                  ),
                ),

                SizedBox(width: 16.w),

                // Text
                Expanded(
                  child: Text(
                    page.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                      fontFamily: 'Poppins',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final bool isIntroPage;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.isIntroPage = false,
  });
}
