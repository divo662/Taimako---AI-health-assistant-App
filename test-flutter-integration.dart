import 'dart:convert';
import 'package:http/http.dart' as http;

/// =====================================================
/// TAIMAKO FLUTTER INTEGRATION TEST
/// =====================================================
///
/// This Dart script tests the Flutter app's ability to
/// connect to Supabase Edge Functions
///
/// Run: dart test-flutter-integration.dart

class TaimakoIntegrationTest {
  static const String supabaseUrl = 'https://pcqfdxgajkojuffiiykt.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjcWZkeGdhamtvanVmZmlpeWt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4NzYyMzYsImV4cCI6MjA3NjQ1MjIzNn0.lf0e9v-qyOXPa_GQPsBRbyMH_VfcNJS2oash49RD_ik';
  static const String testUserId =
      'ce0dfef5-fdbc-40ce-9d11-4045aec499b3'; // Real authenticated user

  /// Test predict-illness Edge Function
  static Future<Map<String, dynamic>> testPredictIllness() async {
    print('🔍 Testing predict-illness Edge Function...');

    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/predict-illness'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
          'apikey': supabaseAnonKey,
        },
        body: json.encode({
          'user_id': testUserId,
          'symptoms': ['fever', 'chills', 'headache', 'body_aches'],
          'age_group': 'adult_20_64',
          'gender': 'male',
          'season': 'rainy_season',
          'location': 'Lagos, Nigeria',
        }),
      );

      print('   Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final prediction = data['predictions'][0];
          print('   ✅ Success! Predicted: ${prediction['conditionName']}');
          print('   📊 Confidence: ${prediction['confidencePercentage']}');
          print('   ⚠️  Urgency: ${prediction['urgencyLevel']}');

          if (data['hedera_transaction_id'] != null) {
            print('   🔗 Hedera TX: ${data['hedera_transaction_id']}');
          }

          return {
            'success': true,
            'prediction_id': data['prediction_id'],
            'hedera_transaction_id': data['hedera_transaction_id'],
            'prediction': prediction,
          };
        } else {
          print('   ❌ API returned success: false');
          return {'success': false, 'error': 'API returned success: false'};
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        print('   Response: ${response.body}');
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('   ❌ Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test get-health-stats Edge Function
  static Future<Map<String, dynamic>> testHealthStats() async {
    print('\n📊 Testing get-health-stats Edge Function...');

    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/get-health-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
          'apikey': supabaseAnonKey,
        },
        body: json.encode({
          'user_id': testUserId,
          'stat_type': 'summary',
          'time_period': '30days',
        }),
      );

      print('   Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print(
              '   ✅ Success! Total predictions: ${data['data']['total_predictions']}');
          print(
              '   🎯 Most common illness: ${data['data']['most_common_illness']}');
          return {'success': true, 'data': data['data']};
        } else {
          print('   ❌ API returned success: false');
          return {'success': false, 'error': 'API returned success: false'};
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        print('   Response: ${response.body}');
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('   ❌ Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test AI conversation
  static Future<Map<String, dynamic>> testAIConversation() async {
    print('\n🤖 Testing AI conversation...');

    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/get-health-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
          'apikey': supabaseAnonKey,
        },
        body: json.encode({
          'user_id': testUserId,
          'stat_type': 'conversation',
          'query': 'What should I do about my fever?',
        }),
      );

      print('   Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final aiResponse = data['data']['response'];
          print('   ✅ AI Response: ${aiResponse.substring(0, 100)}...');
          return {'success': true, 'response': aiResponse};
        } else {
          print('   ❌ API returned success: false');
          return {'success': false, 'error': 'API returned success: false'};
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        print('   Response: ${response.body}');
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('   ❌ Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    print('🚀 TAIMAKO FLUTTER INTEGRATION TEST');
    print('====================================');
    print('👤 Test User: $testUserId');
    print('🌐 Supabase: $supabaseUrl\n');

    int passed = 0;
    int total = 3;

    // Test 1: Predict Illness
    final predictionResult = await testPredictIllness();
    if (predictionResult['success'] == true) passed++;

    // Test 2: Health Stats
    final statsResult = await testHealthStats();
    if (statsResult['success'] == true) passed++;

    // Test 3: AI Conversation
    final conversationResult = await testAIConversation();
    if (conversationResult['success'] == true) passed++;

    // Results
    print('\n🏁 TEST RESULTS');
    print('================');
    print('📊 Total Tests: $total');
    print('✅ Passed: $passed');
    print('❌ Failed: ${total - passed}');
    print('📈 Success Rate: ${((passed / total) * 100).toStringAsFixed(1)}%');

    if (passed == total) {
      print('\n🎉 ALL TESTS PASSED!');
      print('✅ Your Flutter app is ready to integrate with Edge Functions');
    } else if (passed >= 2) {
      print('\n⚠️  MOSTLY WORKING');
      print('🔧 Some issues detected, but core functionality works');
    } else {
      print('\n❌ NEEDS ATTENTION');
      print('🛠️  Multiple issues detected, check Edge Function configuration');
    }
  }
}

/// Main function
void main() async {
  await TaimakoIntegrationTest.runAllTests();
}
