import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, dynamic>> _emergencyContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId != null) {
        final profile = await supabaseService.getCompleteUserProfile(userId);
        final contacts = List<Map<String, dynamic>>.from(
            profile?['emergency_contacts'] ?? []);

        setState(() {
          _emergencyContacts = contacts;
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
            content: Text('Failed to load emergency contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addEmergencyContact() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddEmergencyContactDialog(),
    );

    if (result != null) {
      try {
        final supabaseService =
            Provider.of<SupabaseService>(context, listen: false);
        final userId = supabaseService.currentUser?.id;

        if (userId != null) {
          final currentContacts =
              List<Map<String, dynamic>>.from(_emergencyContacts);
          currentContacts.add({
            ...result,
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'created_at': DateTime.now().toIso8601String(),
          });

          await supabaseService.updateUserProfileData(
            userId: userId,
            profileData: {
              'emergency_contacts': currentContacts,
            },
          );

          setState(() {
            _emergencyContacts = currentContacts;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Emergency contact added successfully'),
                backgroundColor: Color(0xFF00D4AA),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add emergency contact: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteEmergencyContact(int index) async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId != null) {
        final currentContacts =
            List<Map<String, dynamic>>.from(_emergencyContacts);
        currentContacts.removeAt(index);

        await supabaseService.updateUserProfileData(
          userId: userId,
          profileData: {
            'emergency_contacts': currentContacts,
          },
        );

        setState(() {
          _emergencyContacts = currentContacts;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency contact deleted successfully'),
              backgroundColor: Color(0xFF00D4AA),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete emergency contact: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _callEmergencyContact(String phoneNumber) {
    // In a real app, you would use url_launcher to make the call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: const Color(0xFF00D4AA),
      ),
    );
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
          'Emergency Contacts',
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
              Icons.add,
              color: const Color(0xFF00D4AA),
              size: 24.sp,
            ),
            onPressed: _addEmergencyContact,
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
                  // Emergency Info
                  _buildEmergencyInfo(),

                  SizedBox(height: 24.h),

                  // Contacts List
                  _buildContactsList(),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
    );
  }

  Widget _buildEmergencyInfo() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emergency,
                color: const Color(0xFFFF6B6B),
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Emergency Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF6B6B),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'In case of emergency, contact:',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF2C2C2E),
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '• National Emergency: 112',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF2C2C2E),
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            '• Police: 199',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF2C2C2E),
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            '• Fire Service: 199',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF2C2C2E),
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            '• Ambulance: 199',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF2C2C2E),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Emergency Contacts',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 16.h),
        if (_emergencyContacts.isEmpty)
          _buildEmptyState()
        else
          ..._emergencyContacts.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;
            return _buildContactCard(contact, index);
          }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emergency,
                size: 40.sp,
                color: const Color(0xFF8E8E93),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Emergency Contacts',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C2C2E),
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add emergency contacts to ensure quick access during emergencies',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF8E8E93),
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact, int index) {
    final name = contact['name'] ?? 'Unknown';
    final phone = contact['phone'] ?? '';
    final relationship = contact['relationship'] ?? '';
    final isPrimary = contact['is_primary'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isPrimary ? const Color(0xFF00D4AA) : const Color(0xFFE5E5EA),
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color:
                  isPrimary ? const Color(0xFF00D4AA) : const Color(0xFFF2F2F7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 24.sp,
              color: isPrimary ? Colors.white : const Color(0xFF8E8E93),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2C2E),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (isPrimary) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4AA),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'PRIMARY',
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                if (relationship.isNotEmpty)
                  Text(
                    relationship,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF8E8E93),
                      fontFamily: 'Poppins',
                    ),
                  ),
                SizedBox(height: 4.h),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF2C2C2E),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(
                  Icons.phone,
                  color: const Color(0xFF00D4AA),
                  size: 24.sp,
                ),
                onPressed: () => _callEmergencyContact(phone),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: const Color(0xFFFF6B6B),
                  size: 20.sp,
                ),
                onPressed: () => _showDeleteDialog(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Contact',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          'Are you sure you want to delete this emergency contact?',
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
              _deleteEmergencyContact(index);
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

class _AddEmergencyContactDialog extends StatefulWidget {
  @override
  State<_AddEmergencyContactDialog> createState() =>
      _AddEmergencyContactDialogState();
}

class _AddEmergencyContactDialogState
    extends State<_AddEmergencyContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  bool _isPrimary = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Add Emergency Contact',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'e.g., John Doe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g., +234 801 234 5678',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _relationshipController,
              decoration: InputDecoration(
                labelText: 'Relationship',
                hintText: 'e.g., Spouse, Parent, Sibling',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            CheckboxListTile(
              title: Text(
                'Set as Primary Contact',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: Text(
                'This contact will be called first in emergencies',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF8E8E93),
                  fontFamily: 'Poppins',
                ),
              ),
              value: _isPrimary,
              onChanged: (value) {
                setState(() {
                  _isPrimary = value ?? false;
                });
              },
              activeColor: const Color(0xFF00D4AA),
            ),
          ],
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
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'relationship': _relationshipController.text.trim(),
                'is_primary': _isPrimary,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4AA),
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Add Contact',
            style: TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}
