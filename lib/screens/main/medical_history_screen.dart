import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../services/health_prediction_service.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  List<Map<String, dynamic>> _medicalHistory = [];
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicalHistory();
  }

  Future<void> _loadMedicalHistory() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final healthService =
          Provider.of<HealthPredictionService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId != null) {
        // Load user profile for medical history
        final profile = await supabaseService.getCompleteUserProfile(userId);
        final medicalHistory =
            List<Map<String, dynamic>>.from(profile?['medical_history'] ?? []);

        // Load predictions
        final predictions =
            await healthService.getUserPredictionHistory(userId);

        setState(() {
          _medicalHistory = medicalHistory;
          _predictions = predictions;
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
            content: Text('Failed to load medical history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addMedicalEntry() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddMedicalEntryDialog(),
    );

    if (result != null) {
      try {
        final supabaseService =
            Provider.of<SupabaseService>(context, listen: false);
        final userId = supabaseService.currentUser?.id;

        if (userId != null) {
          final currentHistory =
              List<Map<String, dynamic>>.from(_medicalHistory);
          currentHistory.add({
            ...result,
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'created_at': DateTime.now().toIso8601String(),
          });

          await supabaseService.updateUserProfileData(
            userId: userId,
            profileData: {
              'medical_history': currentHistory,
            },
          );

          setState(() {
            _medicalHistory = currentHistory;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Medical entry added successfully'),
                backgroundColor: Color(0xFF00D4AA),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add medical entry: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
          'Medical History',
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
            onPressed: _addMedicalEntry,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
              ),
            )
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: const Color(0xFF00D4AA),
                      unselectedLabelColor: const Color(0xFF8E8E93),
                      indicatorColor: const Color(0xFF00D4AA),
                      labelStyle: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                      tabs: [
                        Tab(text: 'Medical Records'),
                        Tab(text: 'AI Predictions'),
                      ],
                    ),
                  ),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMedicalRecordsTab(),
                        _buildPredictionsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMedicalRecordsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_medicalHistory.isEmpty)
            _buildEmptyState(
              icon: Icons.medical_services,
              title: 'No Medical Records',
              subtitle: 'Add your medical history to keep track of your health',
            )
          else
            ..._medicalHistory.map((entry) => _buildMedicalEntryCard(entry)),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_predictions.isEmpty)
            _buildEmptyState(
              icon: Icons.psychology,
              title: 'No AI Predictions',
              subtitle:
                  'Start chatting with Taimako to see your health predictions here',
            )
          else
            ..._predictions
                .map((prediction) => _buildPredictionCard(prediction)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
                icon,
                size: 40.sp,
                color: const Color(0xFF8E8E93),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C2C2E),
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
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

  Widget _buildMedicalEntryCard(Map<String, dynamic> entry) {
    final condition = entry['condition'] ?? 'Unknown';
    final date = DateTime.tryParse(entry['created_at'] ?? '') ?? DateTime.now();
    final notes = entry['notes'] ?? '';
    final doctor = entry['doctor'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.medical_services,
                  size: 20.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2C2E),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _formatDateTime(date),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF8E8E93),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (doctor.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16.sp,
                  color: const Color(0xFF8E8E93),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Dr. $doctor',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF8E8E93),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
          if (notes.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              notes,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF2C2C2E),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final illness = prediction['prediction_data']?['illness'] ?? 'Unknown';
    final urgency = prediction['prediction_data']?['urgency'] ?? 'moderate';
    final symptoms = List<String>.from(prediction['symptoms'] ?? []);
    final createdAt =
        DateTime.tryParse(prediction['created_at'] ?? '') ?? DateTime.now();

    Color urgencyColor;
    switch (urgency) {
      case 'critical':
      case 'high':
        urgencyColor = const Color(0xFFFF6B6B);
        break;
      case 'moderate':
        urgencyColor = const Color(0xFFFFA726);
        break;
      default:
        urgencyColor = const Color(0xFF4CAF50);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.psychology,
                  size: 20.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      illness,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2C2E),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _formatDateTime(createdAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF8E8E93),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  urgency.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: urgencyColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          if (symptoms.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'Symptoms: ${symptoms.join(', ')}',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF8E8E93),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class _AddMedicalEntryDialog extends StatefulWidget {
  @override
  State<_AddMedicalEntryDialog> createState() => _AddMedicalEntryDialogState();
}

class _AddMedicalEntryDialogState extends State<_AddMedicalEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _conditionController = TextEditingController();
  final _doctorController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _conditionController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Add Medical Entry',
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
              controller: _conditionController,
              decoration: InputDecoration(
                labelText: 'Condition/Diagnosis',
                hintText: 'e.g., Hypertension, Diabetes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a condition';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _doctorController,
              decoration: InputDecoration(
                labelText: 'Doctor/Healthcare Provider',
                hintText: 'e.g., Dr. John Smith',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Additional information about the condition',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              maxLines: 3,
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
                'condition': _conditionController.text.trim(),
                'doctor': _doctorController.text.trim(),
                'notes': _notesController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4AA),
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Add Entry',
            style: TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}
