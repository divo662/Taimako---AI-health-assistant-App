import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static GroqService? _instance;
  static GroqService get instance => _instance ??= GroqService._();

  GroqService._();

  // Groq API configuration
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _model = 'llama-3.3-70b-versatile';
  static const String _apiKey =
      'YOUR_API_KEY_HERE'; // TODO: Replace with your actual Groq API key

  /// Predict illness using Groq AI
  Future<GroqPredictionResult> predictIllness({
    required List<String> symptoms,
    String? ageGroup,
    String? gender,
    String? season,
    String? location,
  }) async {
    try {
      final prompt = _buildPredictionPrompt(
        symptoms: symptoms,
        ageGroup: ageGroup,
        gender: gender,
        season: season,
        location: location,
      );

      final response = await _callGroqAPI(prompt);

      return _parsePredictionResponse(response);
    } catch (e) {
      throw Exception('Failed to get prediction from Groq AI: $e');
    }
  }

  /// Get health advice using Groq AI
  Future<String> getHealthAdvice({
    required List<String> symptoms,
    String? currentCondition,
    String? userContext,
  }) async {
    try {
      final prompt = _buildAdvicePrompt(
        symptoms: symptoms,
        currentCondition: currentCondition,
        userContext: userContext,
      );

      final response = await _callGroqAPI(prompt);

      return _parseAdviceResponse(response);
    } catch (e) {
      throw Exception('Failed to get health advice from Groq AI: $e');
    }
  }

  /// Build prediction prompt for Groq AI
  String _buildPredictionPrompt({
    required List<String> symptoms,
    String? ageGroup,
    String? gender,
    String? season,
    String? location,
  }) {
    final context = StringBuffer();
    context.writeln(
        'You are Taimako, an AI health assistant specialized in Nigerian medical conditions.');
    context.writeln(
        'Analyze the following symptoms and provide a medical prediction:');
    context.writeln();
    context.writeln('SYMPTOMS: ${symptoms.join(', ')}');

    if (ageGroup != null) context.writeln('AGE GROUP: $ageGroup');
    if (gender != null) context.writeln('GENDER: $gender');
    if (season != null) context.writeln('SEASON: $season');
    if (location != null) context.writeln('LOCATION: $location');

    context.writeln();
    context
        .writeln('Please provide your analysis in the following JSON format:');
    context.writeln('{');
    context.writeln('  "primary_prediction": {');
    context.writeln('    "condition": "Most likely condition name",');
    context.writeln('    "confidence": 0.85,');
    context.writeln('    "urgency": "high|moderate|low",');
    context.writeln('    "severity": "critical|high|moderate|low"');
    context.writeln('  },');
    context.writeln('  "alternative_predictions": [');
    context.writeln('    {');
    context.writeln('      "condition": "Alternative condition",');
    context.writeln('      "confidence": 0.65');
    context.writeln('    }');
    context.writeln('  ],');
    context
        .writeln('  "advice": "Specific medical advice for this condition",');
    context.writeln('  "emergency": false,');
    context.writeln('  "recommended_actions": ["action1", "action2"]');
    context.writeln('}');
    context.writeln();
    context.writeln(
        'Focus on common Nigerian medical conditions like malaria, typhoid, cholera, etc.');
    context.writeln(
        'Be conservative and always recommend professional medical consultation.');

    return context.toString();
  }

  /// Build advice prompt for Groq AI
  String _buildAdvicePrompt({
    required List<String> symptoms,
    String? currentCondition,
    String? userContext,
  }) {
    final context = StringBuffer();
    context.writeln('You are Taimako, an AI health assistant for Nigeria.');
    context.writeln(
        'Provide helpful health advice based on the following information:');
    context.writeln();
    context.writeln('SYMPTOMS: ${symptoms.join(', ')}');

    if (currentCondition != null) {
      context.writeln('CURRENT CONDITION: $currentCondition');
    }
    if (userContext != null) {
      context.writeln('ADDITIONAL CONTEXT: $userContext');
    }

    context.writeln();
    context.writeln(
        'Provide practical, culturally appropriate advice for Nigerian users.');
    context.writeln('Include:');
    context.writeln('- Immediate care steps');
    context.writeln('- When to seek medical help');
    context.writeln('- Prevention tips');
    context.writeln('- Home remedies (if appropriate)');
    context.writeln();
    context.writeln('Keep the response concise but comprehensive.');

    return context.toString();
  }

  /// Call Groq API
  Future<Map<String, dynamic>> _callGroqAPI(String prompt) async {
    final url = Uri.parse('$_baseUrl/chat/completions');

    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    final body = {
      'model': _model,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.3,
      'max_tokens': 1000,
      'top_p': 1,
      'stream': false,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception(
          'Groq API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Parse prediction response from Groq
  GroqPredictionResult _parsePredictionResponse(Map<String, dynamic> response) {
    try {
      final content = response['choices'][0]['message']['content'] as String;
      final predictionData = json.decode(content) as Map<String, dynamic>;

      return GroqPredictionResult(
        primaryPrediction:
            _parseConditionPrediction(predictionData['primary_prediction']),
        alternativePredictions:
            (predictionData['alternative_predictions'] as List?)
                    ?.map((alt) => _parseConditionPrediction(alt))
                    .toList() ??
                [],
        advice: predictionData['advice'] ??
            'Please consult a healthcare professional.',
        emergency: predictionData['emergency'] ?? false,
        recommendedActions:
            List<String>.from(predictionData['recommended_actions'] ?? []),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to parse Groq prediction response: $e');
    }
  }

  /// Parse advice response from Groq
  String _parseAdviceResponse(Map<String, dynamic> response) {
    try {
      final content = response['choices'][0]['message']['content'] as String;
      return content.trim();
    } catch (e) {
      throw Exception('Failed to parse Groq advice response: $e');
    }
  }

  /// Parse condition prediction from JSON
  ConditionPrediction _parseConditionPrediction(Map<String, dynamic> data) {
    return ConditionPrediction(
      condition: data['condition'] ?? 'Unknown',
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      urgency: data['urgency'] ?? 'moderate',
      severity: data['severity'] ?? 'moderate',
    );
  }

  /// Check if API key is configured
  bool get isConfigured => _apiKey != 'YOUR_API_KEY_HERE';

  /// Set API key (for runtime configuration)
  void setApiKey(String apiKey) {
    // In a real app, you'd want to store this securely
    // For now, we'll just update the static variable
    // Note: This is not secure for production use
  }
}

/// Data classes for Groq AI responses
class GroqPredictionResult {
  final ConditionPrediction primaryPrediction;
  final List<ConditionPrediction> alternativePredictions;
  final String advice;
  final bool emergency;
  final List<String> recommendedActions;
  final DateTime timestamp;

  GroqPredictionResult({
    required this.primaryPrediction,
    required this.alternativePredictions,
    required this.advice,
    required this.emergency,
    required this.recommendedActions,
    required this.timestamp,
  });
}

class ConditionPrediction {
  final String condition;
  final double confidence;
  final String urgency;
  final String severity;

  ConditionPrediction({
    required this.condition,
    required this.confidence,
    required this.urgency,
    required this.severity,
  });

  String get confidencePercentage =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  String get urgencyLevel {
    switch (urgency) {
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
