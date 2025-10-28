import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../services/health_prediction_service.dart';
import '../../services/supabase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPredictions() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId != null) {
        final healthService =
            Provider.of<HealthPredictionService>(context, listen: false);
        final predictions =
            await healthService.getUserPredictionHistory(userId);

        setState(() {
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
            content: Text('Failed to load history: $e'),
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
          'Chats History',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search your chats...',
                  hintStyle: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF8E8E93),
                    fontFamily: 'Poppins',
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: const Color(0xFF8E8E93),
                    size: 20.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                onChanged: (value) {
                  // Implement search functionality
                },
              ),
            ),
          ),

          // Chat Count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Text(
                  '${_predictions.length} Chats with Taimako',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF8E8E93),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Chat List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                    ),
                  )
                : _predictions.isEmpty
                    ? _buildEmptyState()
                    : _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40.sp,
              color: const Color(0xFF8E8E93),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Chats Yet',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C2C2E),
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start a conversation with Taimako to see your health chats here',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF8E8E93),
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _predictions.length + 1, // +1 for "View more" button
      itemBuilder: (context, index) {
        if (index == _predictions.length) {
          return _buildViewMoreButton();
        }

        final prediction = _predictions[index];
        return _buildChatCard(prediction);
      },
    );
  }

  Widget _buildChatCard(Map<String, dynamic> prediction) {
    final predictionData =
        prediction['prediction_data'] as Map<String, dynamic>?;
    final symptoms = List<String>.from(prediction['symptoms'] ?? []);
    final illness = predictionData?['illness'] ?? 'Health Consultation';
    final createdAt =
        DateTime.tryParse(prediction['created_at'] ?? '') ?? DateTime.now();

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
                  shape: BoxShape.circle,
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
                      illness,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2C2E),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4.h),
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
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: const Color(0xFF8E8E93),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewMoreButton() {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'View more',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF8E8E93),
              fontFamily: 'Poppins',
            ),
          ),
        ),
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
