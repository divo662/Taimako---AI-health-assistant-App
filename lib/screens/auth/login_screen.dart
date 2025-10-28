import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    print('=== LOGIN START ===');
    print('Email: ${_emailController.text.trim()}');
    print(
        'Password: ${_passwordController.text.isNotEmpty ? '[PROVIDED]' : '[EMPTY]'}');

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Getting SupabaseService...');
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      print('SupabaseService obtained');

      // Ensure the service is initialized
      if (!supabaseService.isInitialized) {
        print('⚠️ SupabaseService not initialized, initializing now...');
        await supabaseService.initialize();
        print('✅ SupabaseService initialized');
      }

      print('Calling signInWithPassword...');
      final authResponse = await supabaseService.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('Login successful!');
      print('User ID: ${authResponse.user?.id}');
      print('Session exists: ${authResponse.session != null}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Taimako!'),
            backgroundColor: Color(0xFF00D4AA),
          ),
        );

        // Navigation will happen automatically via AppWrapper auth state listener
        // No need to manually navigate
      }
    } catch (e) {
      print('=== LOGIN ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Error toString: ${e.toString()}');
      print('Stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${_getErrorMessage(e.toString())}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      print('=== LOGIN END ===');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please check your credentials.';
    } else if (error.contains('Email not confirmed')) {
      return 'Please check your email and confirm your account.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60.h),

                // Title
                Text(
                  'Welcome To Taimako',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C2C2E),
                    fontFamily: 'Poppins',
                  ),
                ),

                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  'Check your symptoms and get health insights instantly',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF8E8E93),
                    fontFamily: 'Poppins',
                  ),
                ),

                SizedBox(height: 40.h),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF2C2C2E), // Black text color
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter Email address',
                    hintStyle: TextStyle(
                      fontSize: 16.sp,
                      color: const Color(0xFF8E8E93),
                      fontFamily: 'Poppins',
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF2C2C2E), // Black text color
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter Password',
                    hintStyle: TextStyle(
                      fontSize: 16.sp,
                      color: const Color(0xFF8E8E93),
                      fontFamily: 'Poppins',
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color(0xFF8E8E93),
                        size: 20.sp,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Divider with "or"
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1.h,
                        color: const Color(0xFFE5E5EA),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'or',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF8E8E93),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1.h,
                        color: const Color(0xFFE5E5EA),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Sign Up Link
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: const Color(0xFF8E8E93),
                        fontFamily: 'Poppins',
                      ),
                      children: [
                        const TextSpan(text: 'Do not have an account? '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegistrationScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: const Color(0xFF00D4AA),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                // Terms and Privacy
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF8E8E93),
                        fontFamily: 'Poppins',
                      ),
                      children: const [
                        TextSpan(text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'terms and conditions',
                          style: TextStyle(
                            color: Color(0xFF00D4AA),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
}
