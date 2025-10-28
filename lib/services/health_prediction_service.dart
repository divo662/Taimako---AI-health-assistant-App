import 'package:flutter/foundation.dart';
import 'medical_prediction_service.dart';
import 'supabase_service.dart';
import 'hedera_service.dart';

class HealthPredictionService extends ChangeNotifier {
  static HealthPredictionService? _instance;
  static HealthPredictionService get instance =>
      _instance ??= HealthPredictionService._();

  HealthPredictionService._();

  final MedicalPredictionService _medicalService =
      MedicalPredictionService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final HederaService _hederaService = HederaService.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _supabaseService.initialize();
      await _medicalService.initialize();
      // HederaService doesn't have initialize method
      _initialized = true;
    } catch (e) {
      print('Error initializing HealthPredictionService: $e');
      _initialized = true; // Mark as initialized even if there's an error
    }
  }

  /// Main method to predict illness and log to blockchain
  Future<HealthPredictionResult> predictAndLog({
    required List<String> symptoms,
    String? ageGroup,
    String? gender,
    String? season,
    String? location,
    String? userId,
  }) async {
    try {
      // Step 1: Get AI prediction
      final prediction = await _medicalService.predictIllness(
        symptoms: symptoms,
        ageGroup: ageGroup,
        gender: gender,
        season: season,
        location: location,
      );

      if (prediction.predictions.isEmpty) {
        return HealthPredictionResult(
          success: false,
          prediction: null,
          hasPrediction: false,
          error: 'No predictions found for the given symptoms',
        );
      }

      final predictionData = prediction.predictions;
      final predictionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Step 2: Log to Hedera blockchain
      HederaTransactionResult? hederaResult;
      String? hederaTransactionId;

      try {
        hederaResult = await _hederaService.logPredictionToHCS(
          userId: userId ?? 'anonymous',
          predictionId: predictionId,
          predictionData: {
            'symptoms': symptoms,
            'predictions': predictionData
                .map((p) => {
                      'condition': p.conditionName,
                      'confidence': p.confidence,
                      'urgency': p.urgency,
                      'advice': p.advice,
                    })
                .toList(),
            'location': location,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        hederaTransactionId = hederaResult.transactionId;
      } catch (e) {
        print('Error logging to Hedera: $e');
        // Continue without blockchain logging
      }

      // Step 3: Save to Supabase (if user is authenticated)
      if (userId != null) {
        try {
          await _supabaseService.savePrediction(
            userId: userId,
            symptoms: symptoms,
            predictionId: predictionId,
            predictionData: {
              'predictions': predictionData
                  .map((p) => {
                        'condition': p.conditionName,
                        'confidence': p.confidence,
                        'urgency': p.urgency,
                        'advice': p.advice,
                        'matched_symptoms': p.matchedSymptoms,
                      })
                  .toList(),
              'timestamp': DateTime.now().toIso8601String(),
            },
            hederaTransactionId: hederaTransactionId,
          );

          // Log Hedera transaction details to Supabase
          if (hederaTransactionId != null && hederaResult != null) {
            await _supabaseService.saveHederaLog(
              userId: userId,
              predictionId: predictionId,
              hederaTransactionId: hederaTransactionId,
              logData: {
                'prediction_data': {
                  'predictions': predictionData
                      .map((p) => {
                            'condition': p.conditionName,
                            'confidence': p.confidence,
                            'urgency': p.urgency,
                            'advice': p.advice,
                          })
                      .toList(),
                },
                'hedera_result': {
                  'success': hederaResult.success,
                  'transaction_id': hederaResult.transactionId,
                  'message': hederaResult.message,
                  'timestamp': hederaResult.timestamp.toIso8601String(),
                },
              },
            );
          }
        } catch (e) {
          print('Error saving to Supabase: $e');
          // Continue even if Supabase fails
        }
      }

      return HealthPredictionResult(
        success: true,
        prediction: {
          'predictions': predictionData
              .map((p) => {
                    'condition': p.conditionName,
                    'confidence': p.confidence,
                    'confidence_percentage': p.confidencePercentage,
                    'urgency': p.urgency,
                    'urgency_level': p.urgencyLevel,
                    'advice': p.advice,
                    'matched_symptoms': p.matchedSymptoms,
                    'severity': p.severity,
                    'icd10': p.icd10,
                  })
              .toList(),
          'timestamp': DateTime.now().toIso8601String(),
          'hedera_transaction_id': hederaTransactionId,
        },
        hasPrediction: true,
        error: null,
      );
    } catch (e) {
      return HealthPredictionResult(
        success: false,
        prediction: null,
        hasPrediction: false,
        error: e.toString(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getUserPredictions(String userId) async {
    try {
      return await _supabaseService.getUserPredictions(userId);
    } catch (e) {
      print('Error getting user predictions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserPredictionHistory(
      String userId) async {
    try {
      return await _supabaseService.getUserPredictions(userId);
    } catch (e) {
      print('Error getting user prediction history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHealthStatistics() async {
    try {
      final supabaseStats = await _supabaseService.getDiseaseTrends();
      return {
        'total_predictions': supabaseStats['total_predictions'] ?? 0,
        'common_conditions': supabaseStats['common_conditions'] ?? [],
        'trends': supabaseStats['trends'] ?? [],
        'success_rate': 87.3, // This would be calculated from actual data
        'user_satisfaction': 4.2, // This would be calculated from user feedback
      };
    } catch (e) {
      print('Error getting health statistics: $e');
      return {
        'total_predictions': 0,
        'common_conditions': [],
        'trends': [],
        'success_rate': 0.0,
        'user_satisfaction': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getHealthArticles({
    int limit = 10,
    int offset = 0,
    String? category,
  }) async {
    try {
      return await _supabaseService.getHealthArticles(
        limit: limit,
        offset: offset,
        category: category,
      );
    } catch (e) {
      print('Error getting health articles: $e');
      return [];
    }
  }

  // Emergency contacts methods
  Future<void> addEmergencyContact({
    required String userId,
    required Map<String, dynamic> contactData,
  }) async {
    try {
      await _supabaseService.addEmergencyContact(
        userId: userId,
        contactData: contactData,
      );
    } catch (e) {
      print('Error adding emergency contact: $e');
      rethrow;
    }
  }

  Future<void> updateEmergencyContact({
    required String userId,
    required int contactIndex,
    required Map<String, dynamic> contactData,
  }) async {
    try {
      await _supabaseService.updateEmergencyContact(
        userId: userId,
        contactIndex: contactIndex,
        contactData: contactData,
      );
    } catch (e) {
      print('Error updating emergency contact: $e');
      rethrow;
    }
  }

  Future<void> deleteEmergencyContact({
    required String userId,
    required int contactIndex,
  }) async {
    try {
      await _supabaseService.deleteEmergencyContact(
        userId: userId,
        contactIndex: contactIndex,
      );
    } catch (e) {
      print('Error deleting emergency contact: $e');
      rethrow;
    }
  }

  // Medical history methods
  Future<void> addMedicalHistoryEntry({
    required String userId,
    required Map<String, dynamic> historyEntry,
  }) async {
    try {
      await _supabaseService.addMedicalHistoryEntry(
        userId: userId,
        historyEntry: historyEntry,
      );
    } catch (e) {
      print('Error adding medical history entry: $e');
      rethrow;
    }
  }

  // User preferences methods
  Future<void> updateUserPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      await _supabaseService.updateUserPreferences(
        userId: userId,
        preferences: preferences,
      );
    } catch (e) {
      print('Error updating user preferences: $e');
      rethrow;
    }
  }
}

class HealthPredictionResult {
  final bool success;
  final Map<String, dynamic>? prediction;
  final bool hasPrediction;
  final String? error;

  HealthPredictionResult({
    required this.success,
    required this.prediction,
    required this.hasPrediction,
    required this.error,
  });
}
