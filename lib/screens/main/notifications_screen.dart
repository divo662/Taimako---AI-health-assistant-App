import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  // Notification settings
  bool _pushNotifications = true;
  bool _healthAlerts = true;
  bool _medicationReminders = true;
  bool _appointmentReminders = true;
  bool _emergencyAlerts = true;
  bool _weeklyReports = false;
  bool _monthlyReports = false;
  String _notificationTime = '09:00';
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '07:00';
  bool _quietHoursEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId != null) {
        final profile = await supabaseService.getCompleteUserProfile(userId);
        final preferences = profile?['preferences'] ?? {};
        final notificationSettings = preferences['notification_settings'] ?? {};

        setState(() {
          _userProfile = profile;
          _pushNotifications =
              notificationSettings['push_notifications'] ?? true;
          _healthAlerts = notificationSettings['health_alerts'] ?? true;
          _medicationReminders =
              notificationSettings['medication_reminders'] ?? true;
          _appointmentReminders =
              notificationSettings['appointment_reminders'] ?? true;
          _emergencyAlerts = notificationSettings['emergency_alerts'] ?? true;
          _weeklyReports = notificationSettings['weekly_reports'] ?? false;
          _monthlyReports = notificationSettings['monthly_reports'] ?? false;
          _notificationTime =
              notificationSettings['notification_time'] ?? '09:00';
          _quietHoursStart =
              notificationSettings['quiet_hours_start'] ?? '22:00';
          _quietHoursEnd = notificationSettings['quiet_hours_end'] ?? '07:00';
          _quietHoursEnabled =
              notificationSettings['quiet_hours_enabled'] ?? true;
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

  Future<void> _updateNotificationSettings() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId != null) {
        final currentPreferences =
            Map<String, dynamic>.from(_userProfile?['preferences'] ?? {});
        currentPreferences['notification_settings'] = {
          'push_notifications': _pushNotifications,
          'health_alerts': _healthAlerts,
          'medication_reminders': _medicationReminders,
          'appointment_reminders': _appointmentReminders,
          'emergency_alerts': _emergencyAlerts,
          'weekly_reports': _weeklyReports,
          'monthly_reports': _monthlyReports,
          'notification_time': _notificationTime,
          'quiet_hours_start': _quietHoursStart,
          'quiet_hours_end': _quietHoursEnd,
          'quiet_hours_enabled': _quietHoursEnabled,
        };

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
              content: Text('Notification settings updated successfully'),
              backgroundColor: Color(0xFF00D4AA),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notification settings: $e'),
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
          'Notifications',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _updateNotificationSettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: const Color(0xFF00D4AA),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
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
                  // General Notifications
                  _buildSection(
                    title: 'General Notifications',
                    children: [
                      _buildSwitchTile(
                        title: 'Push Notifications',
                        subtitle: 'Receive push notifications from the app',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Health Notifications
                  _buildSection(
                    title: 'Health Notifications',
                    children: [
                      _buildSwitchTile(
                        title: 'Health Alerts',
                        subtitle: 'Get notified about important health updates',
                        value: _healthAlerts,
                        onChanged: (value) {
                          setState(() {
                            _healthAlerts = value;
                          });
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Medication Reminders',
                        subtitle: 'Reminders for taking medications',
                        value: _medicationReminders,
                        onChanged: (value) {
                          setState(() {
                            _medicationReminders = value;
                          });
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Appointment Reminders',
                        subtitle: 'Reminders for upcoming medical appointments',
                        value: _appointmentReminders,
                        onChanged: (value) {
                          setState(() {
                            _appointmentReminders = value;
                          });
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Emergency Alerts',
                        subtitle:
                            'Critical health alerts and emergency notifications',
                        value: _emergencyAlerts,
                        onChanged: (value) {
                          setState(() {
                            _emergencyAlerts = value;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Reports & Updates
                  _buildSection(
                    title: 'Reports & Updates',
                    children: [
                      _buildSwitchTile(
                        title: 'Weekly Health Reports',
                        subtitle:
                            'Receive weekly summaries of your health data',
                        value: _weeklyReports,
                        onChanged: (value) {
                          setState(() {
                            _weeklyReports = value;
                          });
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Monthly Health Reports',
                        subtitle:
                            'Receive monthly comprehensive health reports',
                        value: _monthlyReports,
                        onChanged: (value) {
                          setState(() {
                            _monthlyReports = value;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Timing Settings
                  _buildSection(
                    title: 'Timing Settings',
                    children: [
                      _buildListTile(
                        title: 'Daily Notification Time',
                        subtitle: _notificationTime,
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16.sp,
                          color: const Color(0xFF8E8E93),
                        ),
                        onTap: () => _selectNotificationTime(),
                      ),
                      _buildSwitchTile(
                        title: 'Quiet Hours',
                        subtitle: 'Disable notifications during specific hours',
                        value: _quietHoursEnabled,
                        onChanged: (value) {
                          setState(() {
                            _quietHoursEnabled = value;
                          });
                        },
                      ),
                      if (_quietHoursEnabled) ...[
                        _buildListTile(
                          title: 'Quiet Hours Start',
                          subtitle: _quietHoursStart,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16.sp,
                            color: const Color(0xFF8E8E93),
                          ),
                          onTap: () => _selectQuietHoursStart(),
                        ),
                        _buildListTile(
                          title: 'Quiet Hours End',
                          subtitle: _quietHoursEnd,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16.sp,
                            color: const Color(0xFF8E8E93),
                          ),
                          onTap: () => _selectQuietHoursEnd(),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Notification History
                  _buildSection(
                    title: 'Notification History',
                    children: [
                      _buildListTile(
                        title: 'View Notification History',
                        subtitle: 'See all your past notifications',
                        trailing: Icon(
                          Icons.history,
                          size: 20.sp,
                          color: const Color(0xFF00D4AA),
                        ),
                        onTap: () => _viewNotificationHistory(),
                      ),
                      _buildListTile(
                        title: 'Clear All Notifications',
                        subtitle: 'Remove all notification history',
                        trailing: Icon(
                          Icons.clear_all,
                          size: 20.sp,
                          color: const Color(0xFFFF6B6B),
                        ),
                        onTap: () => _clearAllNotifications(),
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

  void _selectNotificationTime() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.parse('2023-01-01 $_notificationTime:00'),
      ),
    ).then((time) {
      if (time != null) {
        setState(() {
          _notificationTime =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        });
      }
    });
  }

  void _selectQuietHoursStart() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.parse('2023-01-01 $_quietHoursStart:00'),
      ),
    ).then((time) {
      if (time != null) {
        setState(() {
          _quietHoursStart =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        });
      }
    });
  }

  void _selectQuietHoursEnd() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.parse('2023-01-01 $_quietHoursEnd:00'),
      ),
    ).then((time) {
      if (time != null) {
        setState(() {
          _quietHoursEnd =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        });
      }
    });
  }

  void _viewNotificationHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification history feature coming soon'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Notifications',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          'This will clear all your notification history. Are you sure?',
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
                  content: Text('All notifications cleared'),
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
}
