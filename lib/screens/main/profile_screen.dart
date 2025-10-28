import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../services/health_prediction_service.dart';
import 'profile_edit_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'medical_history_screen.dart';
import 'emergency_contacts_screen.dart';
import 'notifications_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId != null) {
        // Load user profile
        final profile = await supabaseService.getCompleteUserProfile(userId);

        // Load analytics data
        final analytics = await _loadAnalyticsData(userId);

        setState(() {
          _userProfile = profile;
          _analytics = analytics;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _loadAnalyticsData(String userId) async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      // Use the new analytics method
      final analytics = await supabaseService.getUserAnalytics(userId);

      print('📊 Analytics data loaded: $analytics');
      return analytics;
    } catch (e) {
      print('❌ Error loading analytics: $e');
      return {
        'total_predictions': 0,
        'critical_predictions': 0,
        'total_conversations': 0,
        'conversations_with_predictions': 0,
        'top_symptoms': [],
        'last_prediction': null,
        'last_conversation': null,
      };
    }
  }

  Future<void> _signOut() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      await supabaseService.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF2C2C2E),
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: const Color(0xFF00D4AA),
              size: 20.sp,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(),

                  SizedBox(height: 24.h),

                  // Quick Stats
                  _buildQuickStats(),

                  SizedBox(height: 24.h),

                  // Analytics Section
                  _buildAnalyticsSection(),

                  SizedBox(height: 24.h),

                  // Settings Sections
                  _buildSettingsSections(),

                  SizedBox(height: 24.h),

                  // Sign Out Button
                  _buildSignOutButton(),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final firstName = _userProfile?['first_name'] ?? 'User';
    final lastName = _userProfile?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = _userProfile?['email'] ?? 'user@example.com';
    final stateName = _userProfile?['state_name'] ?? 'Unknown';
    final lgaName = _userProfile?['lga_name'] ?? '';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C2C2E),
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF8E8E93),
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16.sp,
                      color: const Color(0xFF8E8E93),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        lgaName.isNotEmpty ? '$stateName, $lgaName' : stateName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF8E8E93),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalPredictions = _analytics?['total_predictions'] ?? 0;
    final criticalPredictions = _analytics?['critical_predictions'] ?? 0;
    final totalConversations = _analytics?['total_conversations'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Predictions',
            value: totalPredictions.toString(),
            icon: Icons.medical_services,
            color: const Color(0xFF00D4AA),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            title: 'Critical Cases',
            value: criticalPredictions.toString(),
            icon: Icons.warning,
            color: const Color(0xFFFF6B6B),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            title: 'Chat Sessions',
            value: totalConversations.toString(),
            icon: Icons.chat_bubble_outline,
            color: const Color(0xFF4A90E2),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24.sp,
            color: color,
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C2C2E),
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF8E8E93),
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics & Insights',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 16.h),
        _buildOptionTile(
          icon: Icons.analytics,
          title: 'Health Analytics',
          subtitle: 'View detailed health insights and trends',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
            );
          },
        ),
        _buildOptionTile(
          icon: Icons.history,
          title: 'Medical History',
          subtitle: 'Manage your medical records and history',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const MedicalHistoryScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings & Preferences',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 16.h),

        // Account Settings
        _buildSectionTitle('Account'),
        _buildOptionTile(
          icon: Icons.person_outline,
          title: 'Personal Information',
          subtitle: 'Update your profile and contact details',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen()),
            );
          },
        ),
        _buildOptionTile(
          icon: Icons.location_on_outlined,
          title: 'Location Settings',
          subtitle: 'Manage your location preferences',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen()),
            );
          },
        ),

        SizedBox(height: 16.h),

        // Health Settings
        _buildSectionTitle('Health'),
        _buildOptionTile(
          icon: Icons.emergency,
          title: 'Emergency Contacts',
          subtitle: 'Manage your emergency contact list',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const EmergencyContactsScreen()),
            );
          },
        ),
        _buildOptionTile(
          icon: Icons.medication,
          title: 'Medical History',
          subtitle: 'View and manage your medical records',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const MedicalHistoryScreen()),
            );
          },
        ),

        SizedBox(height: 16.h),

        // App Settings
        _buildSectionTitle('App'),
        _buildOptionTile(
          icon: Icons.settings,
          title: 'General Settings',
          subtitle: 'App preferences and configurations',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        _buildOptionTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage your notification preferences',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationsScreen()),
            );
          },
        ),
        _buildOptionTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy & Security',
          subtitle: 'Control your data and privacy settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8E8E93),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.h),
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: const Color(0xFF00D4AA),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF8E8E93),
            fontFamily: 'Poppins',
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: const Color(0xFF8E8E93),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _signOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B6B),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
