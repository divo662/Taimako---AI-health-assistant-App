import 'dart:convert';
import 'package:flutter/services.dart';

class MedicalPredictionService {
  static MedicalPredictionService? _instance;
  static MedicalPredictionService get instance =>
      _instance ??= MedicalPredictionService._();

  MedicalPredictionService._();

  Map<String, dynamic>? _dataset;
  List<Map<String, dynamic>>? _conditions;

  Future<void> initialize() async {
    if (_dataset != null) return;

    try {
      final String jsonString =
          await rootBundle.loadString('lib/data/nigerian_medical_dataset.json');
      _dataset = json.decode(jsonString);
      _conditions = List<Map<String, dynamic>>.from(_dataset!['conditions']);
    } catch (e) {
      throw Exception('Failed to load medical dataset: $e');
    }
  }

  /// Main prediction method
  Future<PredictionResult> predictIllness({
    required List<String> symptoms,
    String? ageGroup,
    String? gender,
    String? season,
    String? location,
  }) async {
    await initialize();

    if (_conditions == null) {
      throw Exception('Dataset not initialized');
    }

    // Normalize symptoms
    final normalizedSymptoms = _normalizeSymptoms(symptoms);

    // Calculate scores for each condition
    final List<ConditionScore> scores = [];

    for (final condition in _conditions!) {
      final score = _calculateConditionScore(
        condition: condition,
        userSymptoms: normalizedSymptoms,
        ageGroup: ageGroup,
        gender: gender,
        season: season,
        location: location,
      );

      if (score.confidence > 0.3) {
        // Only include conditions with reasonable confidence
        scores.add(score);
      }
    }

    // Sort by confidence score (highest first)
    scores.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Get top predictions
    final topPredictions = scores.take(3).toList();

    return PredictionResult(
      predictions: topPredictions,
      inputSymptoms: symptoms,
      timestamp: DateTime.now(),
      confidence:
          topPredictions.isNotEmpty ? topPredictions.first.confidence : 0.0,
    );
  }

  /// Normalize symptoms to match dataset format
  List<String> _normalizeSymptoms(List<String> symptoms) {
    return symptoms.map((symptom) {
      return symptom
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
          .replaceAll(' ', '_') // Replace spaces with underscores
          .trim();
    }).toList();
  }

  /// Calculate confidence score for a condition
  ConditionScore _calculateConditionScore({
    required Map<String, dynamic> condition,
    required List<String> userSymptoms,
    String? ageGroup,
    String? gender,
    season,
    String? location,
  }) {
    final List<String> conditionSymptoms =
        List<String>.from(condition['symptoms'] ?? []);
    final List<String> primarySymptoms =
        List<String>.from(condition['primary_symptoms'] ?? []);

    // Base confidence from symptom matching
    double baseConfidence = condition['confidence_base']?.toDouble() ?? 0.5;

    // Calculate symptom match score
    final symptomMatchScore = _calculateSymptomMatchScore(
      userSymptoms: userSymptoms,
      conditionSymptoms: conditionSymptoms,
      primarySymptoms: primarySymptoms,
    );

    // Apply age group risk factor
    final ageRiskFactor = _getAgeRiskFactor(condition, ageGroup);

    // Apply gender risk factor
    final genderRiskFactor = _getGenderRiskFactor(condition, gender);

    // Apply seasonal risk factor
    final seasonalRiskFactor = _getSeasonalRiskFactor(condition, season);

    // Calculate final confidence
    double finalConfidence = baseConfidence *
        symptomMatchScore *
        ageRiskFactor *
        genderRiskFactor *
        seasonalRiskFactor;

    // Ensure confidence is between 0 and 1
    finalConfidence = finalConfidence.clamp(0.0, 1.0);

    return ConditionScore(
      conditionId: condition['id'],
      conditionName: condition['name'],
      confidence: finalConfidence,
      matchedSymptoms: _getMatchedSymptoms(userSymptoms, conditionSymptoms),
      advice:
          condition['advice'] ?? 'Please consult a healthcare professional.',
      urgency: condition['urgency'] ?? 'moderate',
      severity: condition['severity'] ?? 'moderate',
      icd10: condition['icd10'],
    );
  }

  /// Calculate how well user symptoms match condition symptoms
  double _calculateSymptomMatchScore({
    required List<String> userSymptoms,
    required List<String> conditionSymptoms,
    required List<String> primarySymptoms,
  }) {
    if (userSymptoms.isEmpty || conditionSymptoms.isEmpty) return 0.0;

    // Count exact matches
    final exactMatches = userSymptoms
        .where((symptom) => conditionSymptoms.contains(symptom))
        .length;

    // Count primary symptom matches (weighted higher)
    final primaryMatches = userSymptoms
        .where((symptom) => primarySymptoms.contains(symptom))
        .length;

    // Calculate base match ratio
    final baseMatchRatio = exactMatches / conditionSymptoms.length;

    // Add bonus for primary symptom matches
    final primaryBonus = primaryMatches * 0.2;

    // Calculate final score
    final score = (baseMatchRatio + primaryBonus).clamp(0.0, 1.0);

    return score;
  }

  /// Get age-related risk factor
  double _getAgeRiskFactor(Map<String, dynamic> condition, String? ageGroup) {
    if (ageGroup == null) return 1.0;

    final ageGroups = condition['age_groups'] as List<dynamic>? ?? [];
    if (ageGroups.contains('all') || ageGroups.contains(ageGroup)) {
      return 1.0;
    }

    // Check for high-risk age groups
    final highRiskGroups = _dataset?['age_group_risks']?[ageGroup]?['high_risk']
            as List<dynamic>? ??
        [];
    if (highRiskGroups.contains(condition['id'])) {
      return 1.2; // 20% higher risk
    }

    return 0.8; // 20% lower risk for non-matching age groups
  }

  /// Get gender-related risk factor
  double _getGenderRiskFactor(Map<String, dynamic> condition, String? gender) {
    if (gender == null) return 1.0;

    final genderRisks = _dataset?['gender_specific_risks']?[gender]
            ?['high_risk'] as List<dynamic>? ??
        [];
    if (genderRisks.contains(condition['id'])) {
      return 1.1; // 10% higher risk
    }

    return 1.0;
  }

  /// Get seasonal risk factor
  double _getSeasonalRiskFactor(
      Map<String, dynamic> condition, String? season) {
    if (season == null) return 1.0;

    final seasonalFactors = _dataset?['seasonal_factors']?[season]
            ?['increased_risk'] as List<dynamic>? ??
        [];
    if (seasonalFactors.contains(condition['id'])) {
      return 1.3; // 30% higher risk during high-risk seasons
    }

    return 1.0;
  }

  /// Get list of matched symptoms
  List<String> _getMatchedSymptoms(
      List<String> userSymptoms, List<String> conditionSymptoms) {
    return userSymptoms
        .where((symptom) => conditionSymptoms.contains(symptom))
        .toList();
  }

  /// Get health advice based on symptoms
  Future<String> getHealthAdvice(List<String> symptoms) async {
    await initialize();

    // Simple advice based on common symptoms
    if (symptoms.any((s) => ['fever', 'high_fever'].contains(s))) {
      return 'Stay hydrated and rest. Monitor your temperature. If fever persists or is very high, seek medical attention.';
    }

    if (symptoms.any(
        (s) => ['cough', 'chest_pain', 'shortness_of_breath'].contains(s))) {
      return 'Rest and avoid smoking. If breathing becomes difficult, seek immediate medical attention.';
    }

    if (symptoms.any((s) => ['diarrhea', 'vomiting'].contains(s))) {
      return 'Stay hydrated with oral rehydration solution. Eat bland foods. Seek medical attention if symptoms persist.';
    }

    return 'Rest, stay hydrated, and monitor your symptoms. If they worsen or persist, consult a healthcare professional.';
  }

  /// Get emergency symptoms that require immediate attention
  List<String> getEmergencySymptoms() {
    return [
      'severe_headache',
      'stiff_neck',
      'high_fever',
      'difficulty_breathing',
      'chest_pain',
      'severe_abdominal_pain',
      'confusion',
      'seizures',
      'unconsciousness',
      'severe_bleeding',
    ];
  }

  /// Check if symptoms indicate emergency
  bool isEmergency(List<String> symptoms) {
    final emergencySymptoms = getEmergencySymptoms();
    return symptoms
        .any((symptom) => emergencySymptoms.contains(symptom.toLowerCase()));
  }
}

/// Data classes for prediction results
class PredictionResult {
  final List<ConditionScore> predictions;
  final List<String> inputSymptoms;
  final DateTime timestamp;
  final double confidence;

  PredictionResult({
    required this.predictions,
    required this.inputSymptoms,
    required this.timestamp,
    required this.confidence,
  });
}

class ConditionScore {
  final String conditionId;
  final String conditionName;
  final double confidence;
  final List<String> matchedSymptoms;
  final String advice;
  final String urgency;
  final String severity;
  final String? icd10;

  ConditionScore({
    required this.conditionId,
    required this.conditionName,
    required this.confidence,
    required this.matchedSymptoms,
    required this.advice,
    required this.urgency,
    required this.severity,
    this.icd10,
  });

  String get confidencePercentage =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  String get urgencyLevel {
    switch (urgency) {
      case 'critical':
        return 'Critical - Seek immediate medical attention';
      case 'high':
        return 'High - Seek medical attention promptly';
      case 'moderate':
        return 'Moderate - Consider medical consultation';
      case 'low':
        return 'Low - Monitor symptoms';
      default:
        return 'Unknown';
    }
  }
}
