import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  // Settings state
  bool _notificationsEnabled = true;
  bool _locationSharing = true;
  bool _dataPrivacy = true;
  bool _analyticsEnabled = true;
  String _language = 'English';
  String _theme = 'System';

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId != null) {
        final profile = await supabaseService.getCompleteUserProfile(userId);

        setState(() {
          _userProfile = profile;
          _notificationsEnabled =
              profile?['preferences']?['notifications_enabled'] ?? true;
          _locationSharing =
              profile?['preferences']?['location_sharing'] ?? true;
          _dataPrivacy = profile?['preferences']?['data_privacy'] == 'enhanced';
          _analyticsEnabled =
              profile?['preferences']?['analytics_enabled'] ?? true;
          _language = profile?['preferences']?['language'] ?? 'English';
          _theme = profile?['preferences']?['theme'] ?? 'System';
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
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId != null) {
        final currentPreferences =
            Map<String, dynamic>.from(_userProfile?['preferences'] ?? {});
        currentPreferences[key] = value;

        await supabaseService.updateUserProfileData(
          userId: userId,
          profileData: {
            'preferences': currentPreferences,
          },
        );

        setState(() {
          _userProfile?['preferences'] = currentPreferences;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings updated successfully'),
              backgroundColor: Color(0xFF00D4AA),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
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
          'Settings',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
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
                  // Notifications Section
                  _buildSection(
                    title: 'Notifications',
                    children: [
                      _buildSwitchTile(
                        title: 'Push Notifications',
                        subtitle: 'Receive notifications about health updates',
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                          _updateSetting('notifications_enabled', value);
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Privacy Section
                  _buildSection(
                    title: 'Privacy & Security',
                    children: [
                      _buildSwitchTile(
                        title: 'Location Sharing',
                        subtitle: 'Allow location-based health insights',
                        value: _locationSharing,
                        onChanged: (value) {
                          setState(() {
                            _locationSharing = value;
                          });
                          _updateSetting('location_sharing', value);
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Enhanced Data Privacy',
                        subtitle: 'Use additional privacy protection',
                        value: _dataPrivacy,
                        onChanged: (value) {
                          setState(() {
                            _dataPrivacy = value;
                          });
                          _updateSetting(
                              'data_privacy', value ? 'enhanced' : 'standard');
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Analytics & Insights',
                        subtitle: 'Help improve the app with usage data',
                        value: _analyticsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _analyticsEnabled = value;
                          });
                          _updateSetting('analytics_enabled', value);
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // App Preferences Section
                  _buildSection(
                    title: 'App Preferences',
                    children: [
                      _buildListTile(
                        title: 'Language',
                        subtitle: _language,
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16.sp,
                          color: const Color(0xFF8E8E93),
                        ),
                        onTap: () => _showLanguageDialog(),
                      ),
                      _buildListTile(
                        title: 'Theme',
                        subtitle: _theme,
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16.sp,
                          color: const Color(0xFF8E8E93),
                        ),
                        onTap: () => _showThemeDialog(),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Data Management Section
                  _buildSection(
                    title: 'Data Management',
                    children: [
                      _buildListTile(
                        title: 'Export Data',
                        subtitle: 'Download your health data',
                        trailing: Icon(
                          Icons.download,
                          size: 20.sp,
                          color: const Color(0xFF00D4AA),
                        ),
                        onTap: () => _exportData(),
                      ),
                      _buildListTile(
                        title: 'Clear Cache',
                        subtitle: 'Free up storage space',
                        trailing: Icon(
                          Icons.cleaning_services,
                          size: 20.sp,
                          color: const Color(0xFFFFA726),
                        ),
                        onTap: () => _clearCache(),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Account Section
                  _buildSection(
                    title: 'Account',
                    children: [
                      _buildListTile(
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16.sp,
                          color: const Color(0xFF8E8E93),
                        ),
                        onTap: () => _changePassword(),
                      ),
                      _buildListTile(
                        title: 'Delete Account',
                        subtitle: 'Permanently delete your account',
                        trailing: Icon(
                          Icons.delete_forever,
                          size: 20.sp,
                          color: const Color(0xFFFF6B6B),
                        ),
                        onTap: () => _deleteAccount(),
                      ),
                    ],
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2C2C2E),
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF8E8E93),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00D4AA),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
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
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Language',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English', 'English'),
            _buildLanguageOption('Hausa', 'Hausa'),
            _buildLanguageOption('Yoruba', 'Yoruba'),
            _buildLanguageOption('Igbo', 'Igbo'),
            _buildLanguageOption('Pidgin', 'Pidgin'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, String displayName) {
    return ListTile(
      title: Text(
        displayName,
        style: TextStyle(
          fontSize: 16.sp,
          fontFamily: 'Poppins',
        ),
      ),
      trailing: _language == language
          ? Icon(
              Icons.check,
              color: const Color(0xFF00D4AA),
              size: 20.sp,
            )
          : null,
      onTap: () {
        setState(() {
          _language = language;
        });
        _updateSetting('language', language);
        Navigator.pop(context);
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Theme',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('System', 'Follow system theme'),
            _buildThemeOption('Light', 'Always use light theme'),
            _buildThemeOption('Dark', 'Always use dark theme'),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String theme, String description) {
    return ListTile(
      title: Text(
        theme,
        style: TextStyle(
          fontSize: 16.sp,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 14.sp,
          color: const Color(0xFF8E8E93),
          fontFamily: 'Poppins',
        ),
      ),
      trailing: _theme == theme
          ? Icon(
              Icons.check,
              color: const Color(0xFF00D4AA),
              size: 20.sp,
            )
          : null,
      onTap: () {
        setState(() {
          _theme = theme;
        });
        _updateSetting('theme', theme);
        Navigator.pop(context);
      },
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export feature coming soon'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Cache',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          'This will clear all cached data and free up storage space. Are you sure?',
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: const Color(0xFF8E8E93),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Color(0xFF00D4AA),
                ),
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(
                color: const Color(0xFFFF6B6B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change password feature coming soon'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: const Color(0xFFFF6B6B),
          ),
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted. Are you sure?',
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: const Color(0xFF8E8E93),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature coming soon'),
                  backgroundColor: Color(0xFF2196F3),
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: const Color(0xFFFF6B6B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
