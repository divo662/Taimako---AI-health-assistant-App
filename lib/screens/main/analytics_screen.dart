import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../services/health_prediction_service.dart';
import '../../services/supabase_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Map<String, dynamic>> _predictions = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final healthService =
          Provider.of<HealthPredictionService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId != null) {
        // Use the new analytics method
        final analytics = await supabaseService.getUserAnalytics(userId);
        final predictions = await supabaseService.getUserPredictions(userId);

        // Calculate analytics
        final totalPredictions = predictions.length;
        final criticalPredictions = predictions
            .where((p) =>
                p['prediction_data']?['urgency'] == 'critical' ||
                p['prediction_data']?['urgency'] == 'high')
            .length;

        final moderatePredictions = predictions
            .where((p) => p['prediction_data']?['urgency'] == 'moderate')
            .length;

        final lowPredictions = predictions
            .where((p) => p['prediction_data']?['urgency'] == 'low')
            .length;

        // Common symptoms analysis
        final commonSymptoms = <String, int>{};
        for (final prediction in predictions) {
          final symptoms = List<String>.from(prediction['symptoms'] ?? []);
          for (final symptom in symptoms) {
            commonSymptoms[symptom] = (commonSymptoms[symptom] ?? 0) + 1;
          }
        }

        final topSymptoms = commonSymptoms.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(10);

        // Common conditions analysis
        final commonConditions = <String, int>{};
        for (final prediction in predictions) {
          final condition =
              prediction['prediction_data']?['illness'] ?? 'Unknown';
          commonConditions[condition] = (commonConditions[condition] ?? 0) + 1;
        }

        final topConditions = commonConditions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(10);

        // Monthly trends
        final monthlyData = <String, int>{};
        for (final prediction in predictions) {
          final date = DateTime.tryParse(prediction['created_at'] ?? '') ??
              DateTime.now();
          final monthKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
        }

        setState(() {
          _predictions = predictions;
          _analytics = {
            ...analytics, // Include all data from getUserAnalytics
            'moderate_predictions': moderatePredictions,
            'low_predictions': lowPredictions,
            'monthly_data': monthlyData,
          };
          _isLoading = false;
        });

        print(
            '📊 Analytics screen data loaded: ${analytics['total_predictions']} predictions');
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
            content: Text('Failed to load analytics: $e'),
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
          'Health Analytics',
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
                  // Overview Cards
                  _buildOverviewCards(),

                  SizedBox(height: 24.h),

                  // Top Symptoms
                  _buildTopSymptoms(),

                  SizedBox(height: 24.h),

                  // Top Conditions
                  _buildTopConditions(),

                  SizedBox(height: 24.h),

                  // Monthly Trends
                  _buildMonthlyTrends(),

                  SizedBox(height: 24.h),

                  // Recent Predictions
                  _buildRecentPredictions(),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final total = _analytics['total_predictions'] ?? 0;
    final critical = _analytics['critical_predictions'] ?? 0;
    final moderate = _analytics['moderate_predictions'] ?? 0;
    final low = _analytics['low_predictions'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Predictions',
                value: total.toString(),
                icon: Icons.medical_services,
                color: const Color(0xFF00D4AA),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                title: 'Critical Cases',
                value: critical.toString(),
                icon: Icons.warning,
                color: const Color(0xFFFF6B6B),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Moderate Cases',
                value: moderate.toString(),
                icon: Icons.info,
                color: const Color(0xFFFFA726),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                title: 'Low Risk',
                value: low.toString(),
                icon: Icons.check_circle,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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

  Widget _buildTopSymptoms() {
    final topSymptoms =
        List<Map<String, dynamic>>.from(_analytics['top_symptoms'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Common Symptoms',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          child: topSymptoms.isEmpty
              ? Center(
                  child: Text(
                    'No symptoms data available',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF8E8E93),
                      fontFamily: 'Poppins',
                    ),
                  ),
                )
              : Column(
                  children: topSymptoms.take(5).map<Widget>((symptom) {
                    final count = symptom['count'] as int;
                    final total = _analytics['total_predictions'] as int;
                    final percentage =
                        total > 0 ? (count / total * 100).round() : 0;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              symptom['symptom'],
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF2C2C2E),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Text(
                            '$count times ($percentage%)',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF8E8E93),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTopConditions() {
    final topConditions =
        List<Map<String, dynamic>>.from(_analytics['top_conditions'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Predicted Conditions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          child: topConditions.isEmpty
              ? Center(
                  child: Text(
                    'No conditions data available',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF8E8E93),
                      fontFamily: 'Poppins',
                    ),
                  ),
                )
              : Column(
                  children: topConditions.take(5).map<Widget>((condition) {
                    final count = condition['count'] as int;
                    final total = _analytics['total_predictions'] as int;
                    final percentage =
                        total > 0 ? (count / total * 100).round() : 0;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              condition['condition'],
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF2C2C2E),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Text(
                            '$count times ($percentage%)',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF8E8E93),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrends() {
    final monthlyData = Map<String, int>.from(_analytics['monthly_data'] ?? {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Trends',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          child: monthlyData.isEmpty
              ? Center(
                  child: Text(
                    'No trend data available',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF8E8E93),
                      fontFamily: 'Poppins',
                    ),
                  ),
                )
              : Column(
                  children: () {
                    final sortedEntries = monthlyData.entries.toList()
                      ..sort((a, b) => a.key.compareTo(b.key))
                      ..take(6);
                    return sortedEntries.map<Widget>((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatMonth(entry.key),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: const Color(0xFF2C2C2E),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value} predictions',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF8E8E93),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  }(),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentPredictions() {
    final recentPredictions = _predictions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Predictions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2C2E),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 16.h),
        ...recentPredictions.map((prediction) {
          final illness =
              prediction['prediction_data']?['illness'] ?? 'Unknown';
          final urgency =
              prediction['prediction_data']?['urgency'] ?? 'moderate';
          final createdAt = DateTime.tryParse(prediction['created_at'] ?? '') ??
              DateTime.now();

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
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    shape: BoxShape.circle,
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
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
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
                Text(
                  urgency.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: urgencyColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatMonth(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length == 2) {
      final year = parts[0];
      final month = int.tryParse(parts[1]) ?? 1;
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${monthNames[month - 1]} $year';
    }
    return monthKey;
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
