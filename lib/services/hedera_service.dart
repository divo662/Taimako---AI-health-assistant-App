import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class HederaService {
  static HederaService? _instance;
  static HederaService get instance => _instance ??= HederaService._();

  HederaService._();

  // Hedera configuration - Replace with your actual values
  static const String hederaNetwork = 'testnet'; // or 'mainnet'
  static const String hederaApiUrl =
      'https://testnet.mirrornode.hedera.com/api/v1'; // or mainnet URL
  static const String hederaHcsTopicId =
      'YOUR_HCS_TOPIC_ID'; // Your HCS topic ID
  static const String hederaAccountId = '';
  static const String hederaPrivateKey =
      '';

  // For MVP, we'll use a simplified approach with HTTP API calls
  // In production, you'd use the Hedera SDK for more robust integration

  /// Log a prediction to Hedera HCS (Consensus Service) via Edge Function
  /// This creates an immutable record of the prediction
  Future<HederaTransactionResult> logPredictionToHCS({
    required String userId,
    required String predictionId,
    required Map<String, dynamic> predictionData,
  }) async {
    try {
      print('🔗 Calling real Hedera Edge Function...');

      // Call the Edge Function that uses real Hedera SDK
      final response = await http.post(
        Uri.parse(
            'https://pcqfdxgajkojuffiiykt.supabase.co/functions/v1/log-to-hedera'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              '',
        },
        body: json.encode({
          'user_id': userId,
          'prediction_id': predictionId,
          'prediction_data': {
            'illness': predictionData['illness'] ?? '',
            'confidence': predictionData['confidence'] ?? 0.0,
            'urgency': predictionData['urgency'] ?? 'moderate',
            'severity': predictionData['severity'] ?? 'moderate',
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transactionId = data['hedera_transaction_id'];
        final explorerUrl = data['explorer_url'];

        print('✅ Real Hedera transaction successful: $transactionId');
        print('🔗 Explorer URL: $explorerUrl');

        return HederaTransactionResult(
          success: true,
          transactionId: transactionId,
          message: 'Prediction logged to Hedera HCS successfully',
          timestamp: DateTime.now(),
        );
      } else {
        print('❌ Edge Function error: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        throw Exception('Hedera Edge Function failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error calling Hedera Edge Function: $e');
      return HederaTransactionResult(
        success: false,
        transactionId: null,
        message: 'Failed to log prediction to Hedera: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Create a hash of the prediction data for integrity verification
  String _createPredictionHash(Map<String, dynamic> predictionData) {
    // Sort the data to ensure consistent hashing
    final sortedData = Map.fromEntries(predictionData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)));

    final jsonString = json.encode(sortedData);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Anonymize user ID for privacy (keep only first 8 characters)
  String _anonymizeUserId(String userId) {
    if (userId.length <= 8) return userId;
    return '${userId.substring(0, 8)}...';
  }

  /// Simulate HCS submission (replace with actual Hedera SDK in production)
  Future<String> _simulateHCSSubmission(Map<String, dynamic> message) async {
    // This is a simulation for MVP
    // In production, you would use the Hedera SDK to submit to HCS

    final messageJson = json.encode(message);
    final messageHash = sha256.convert(utf8.encode(messageJson)).toString();

    // Simulate transaction ID format: 0.0.123456@1234567890.123456789
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomId = (timestamp % 1000000).toString().padLeft(6, '0');
    final transactionId = '0.0.$hederaHcsTopicId@$timestamp.$randomId';

    // Log the transaction for debugging
    print('Hedera HCS Transaction: $transactionId');
    print('Message Hash: $messageHash');
    print('Message: $messageJson');

    return transactionId;
  }

  /// Verify a prediction's integrity using Hedera HCS
  Future<bool> verifyPredictionIntegrity({
    required String transactionId,
    required Map<String, dynamic> predictionData,
  }) async {
    try {
      // In production, you would query the Hedera network to verify the transaction
      // For MVP, we'll simulate the verification

      final expectedHash = _createPredictionHash(predictionData);

      // Simulate network query
      final verificationResult =
          await _simulateHCSVerification(transactionId, expectedHash);

      return verificationResult;
    } catch (e) {
      print('Error verifying prediction integrity: $e');
      return false;
    }
  }

  /// Simulate HCS verification (replace with actual Hedera SDK in production)
  Future<bool> _simulateHCSVerification(
      String transactionId, String expectedHash) async {
    // This is a simulation for MVP
    // In production, you would query the Hedera network

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // For MVP, we'll return true if the transaction ID format is valid
    final isValidFormat =
        RegExp(r'^0\.0\.\d+@\d+\.\d+$').hasMatch(transactionId);

    return isValidFormat;
  }

  /// Get transaction details from Hedera network
  Future<HederaTransactionDetails?> getTransactionDetails(
      String transactionId) async {
    try {
      // In production, you would query the Hedera network
      // For MVP, we'll simulate the response

      final details = await _simulateGetTransactionDetails(transactionId);
      return details;
    } catch (e) {
      print('Error getting transaction details: $e');
      return null;
    }
  }

  /// Simulate getting transaction details (replace with actual Hedera SDK in production)
  Future<HederaTransactionDetails?> _simulateGetTransactionDetails(
      String transactionId) async {
    // This is a simulation for MVP
    // In production, you would query the Hedera network

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Parse transaction ID
    final parts = transactionId.split('@');
    if (parts.length != 2) return null;

    final accountParts = parts[0].split('.');
    if (accountParts.length != 3) return null;

    final timestampParts = parts[1].split('.');
    if (timestampParts.length != 2) return null;

    return HederaTransactionDetails(
      transactionId: transactionId,
      accountId: parts[0],
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(int.parse(timestampParts[0])),
      status: 'SUCCESS',
      fee: 0.0001, // Simulated fee
      memo: 'Health prediction log',
    );
  }

  /// Get health prediction statistics from Hedera logs
  Future<HederaHealthStats> getHealthPredictionStats() async {
    try {
      // In production, you would query the Hedera network for HCS messages
      // For MVP, we'll simulate the statistics

      final stats = await _simulateGetHealthStats();
      return stats;
    } catch (e) {
      print('Error getting health prediction stats: $e');
      return HederaHealthStats(
        totalPredictions: 0,
        uniqueUsers: 0,
        mostCommonIllness: 'Unknown',
        averageConfidence: 0.0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Simulate getting health stats (replace with actual Hedera SDK in production)
  Future<HederaHealthStats> _simulateGetHealthStats() async {
    // This is a simulation for MVP
    // In production, you would query the Hedera network for HCS messages

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    return HederaHealthStats(
      totalPredictions: 1247,
      uniqueUsers: 89,
      mostCommonIllness: 'Malaria',
      averageConfidence: 0.78,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Data classes for Hedera integration
class HederaTransactionResult {
  final bool success;
  final String? transactionId;
  final String message;
  final DateTime timestamp;

  HederaTransactionResult({
    required this.success,
    this.transactionId,
    required this.message,
    required this.timestamp,
  });
}

class HederaTransactionDetails {
  final String transactionId;
  final String accountId;
  final DateTime timestamp;
  final String status;
  final double fee;
  final String memo;

  HederaTransactionDetails({
    required this.transactionId,
    required this.accountId,
    required this.timestamp,
    required this.status,
    required this.fee,
    required this.memo,
  });
}

class HederaHealthStats {
  final int totalPredictions;
  final int uniqueUsers;
  final String mostCommonIllness;
  final double averageConfidence;
  final DateTime lastUpdated;

  HederaHealthStats({
    required this.totalPredictions,
    required this.uniqueUsers,
    required this.mostCommonIllness,
    required this.averageConfidence,
    required this.lastUpdated,
  });
}
