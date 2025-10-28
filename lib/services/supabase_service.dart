import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService extends ChangeNotifier {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  late SupabaseClient _supabase;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    print('=== SUPABASE SERVICE INITIALIZE START ===');
    if (_initialized) {
      print('✅ SupabaseService already initialized');
      return;
    }

    try {
      print('📡 Initializing Supabase client...');
      _supabase = Supabase.instance.client;
      print('📡 Supabase client initialized: ${_supabase.supabaseUrl}');

      _initialized = true;
      print('✅ SupabaseService initialized successfully');
    } catch (e) {
      print('❌ Error initializing SupabaseService: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
    print('=== SUPABASE SERVICE INITIALIZE END ===');
  }

  SupabaseClient get client {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }
    return _supabase;
  }

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithProfile({
    required String email,
    required String password,
    required Map<String, dynamic> userProfileData,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    print('=== SUPABASE SIGNUP START ===');
    print('Email: $email');
    print('User profile data: $userProfileData');

    try {
      // First create the auth user
      print('Creating auth user...');
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      print('Auth response: ${authResponse.user?.id}');

      if (authResponse.user != null) {
        print('User created successfully, creating profile...');
        // Then create the user profile
        await _supabase.from('user_profiles').insert({
          'user_id': authResponse.user!.id,
          ...userProfileData,
        });
        print('Profile created successfully');
      } else {
        print('Failed to create user - no user returned');
      }

      print('=== SUPABASE SIGNUP END ===');
      return authResponse;
    } catch (e) {
      print('=== SUPABASE SIGNUP ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }
    await _supabase.auth.signOut();
  }

  User? get currentUser {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }
    return _supabase.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }
    return _supabase.auth.onAuthStateChange;
  }

  // User profile methods
  Future<Map<String, dynamic>?> getCompleteUserProfile(String userId) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    try {
      // First get the user profile
      final profileResponse = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        return null;
      }

      // Get state information if state_code exists
      if (profileResponse['state_code'] != null) {
        final stateResponse = await _supabase
            .from('nigerian_states')
            .select(
                'state_name, region, climate_zone, malaria_endemicity, emergency_services')
            .eq('state_code', profileResponse['state_code'])
            .maybeSingle();

        if (stateResponse != null) {
          profileResponse['state_name'] = stateResponse['state_name'];
          profileResponse['region'] = stateResponse['region'];
          profileResponse['climate_zone'] = stateResponse['climate_zone'];
          profileResponse['malaria_endemicity'] =
              stateResponse['malaria_endemicity'];
          profileResponse['emergency_services'] =
              stateResponse['emergency_services'];
        }
      }

      // Get LGA information if lga_code exists
      if (profileResponse['lga_code'] != null) {
        final lgaResponse = await _supabase
            .from('nigerian_lgas')
            .select('lga_name, population, urban_rural, healthcare_access')
            .eq('lga_code', profileResponse['lga_code'])
            .maybeSingle();

        if (lgaResponse != null) {
          profileResponse['lga_name'] = lgaResponse['lga_name'];
          profileResponse['lga_population'] = lgaResponse['population'];
          profileResponse['urban_rural'] = lgaResponse['urban_rural'];
          profileResponse['healthcare_access'] =
              lgaResponse['healthcare_access'];
        }
      }

      return profileResponse;
    } catch (e) {
      print('Error loading complete user profile: $e');
      // Return basic profile without location data if there's an error
      return await _supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();
    }
  }

  Future<void> createUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    await _supabase.from('user_profiles').insert({
      'user_id': userId,
      ...profileData,
    });
  }

  Future<void> updateUserProfileData({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    await _supabase.from('user_profiles').update({
      ...profileData,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  // Prediction methods
  Future<void> savePrediction({
    required String userId,
    required List<String> symptoms,
    required String predictionId,
    required Map<String, dynamic> predictionData,
    String? hederaTransactionId,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    await _supabase.from('predictions').insert({
      'id': predictionId,
      'user_id': userId,
      'symptoms': symptoms,
      'prediction_data': predictionData,
      'hedera_transaction_id': hederaTransactionId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveHederaLog({
    required String userId,
    required String predictionId,
    required String hederaTransactionId,
    required Map<String, dynamic> logData,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    await _supabase.from('hedera_logs').insert({
      'user_id': userId,
      'prediction_id': predictionId,
      'hedera_transaction_id': hederaTransactionId,
      'log_data': logData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserPredictions(String userId) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    try {
      // First try to get from the old predictions table
      final response = await _supabase
          .from('predictions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        return List<Map<String, dynamic>>.from(response);
      }

      // If no old predictions, get from conversations/messages (new system)
      final conversations = await getUserConversations(userId);
      List<Map<String, dynamic>> predictions = [];

      for (final conversation in conversations) {
        final conversationData =
            await getConversationWithMessages(conversation['id']);
        if (conversationData != null && conversationData['messages'] != null) {
          for (final message in conversationData['messages']) {
            if (message['message_type'] == 'prediction' &&
                message['prediction_data'] != null) {
              predictions.add({
                'id': message['id'],
                'user_id': userId,
                'symptoms':
                    message['prediction_data']['extracted_symptoms'] ?? [],
                'prediction_data': message['prediction_data'],
                'created_at': message['timestamp'],
                'confidence_score':
                    message['prediction_data']['confidence'] ?? 0.0,
                'urgency': message['prediction_data']['urgency'] ?? 'low',
                'severity': message['prediction_data']['severity'] ?? 'mild',
              });
            }
          }
        }
      }

      return predictions;
    } catch (e) {
      print('Error getting user predictions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getDiseaseTrends() async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    final response = await _supabase
        .from('analytics')
        .select('*')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response ??
        {
          'total_predictions': 0,
          'common_conditions': [],
          'trends': [],
        };
  }

  Future<List<Map<String, dynamic>>> getHealthArticles({
    int limit = 10,
    int offset = 0,
    String? category,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    final response = await _supabase
        .from('health_articles')
        .select('*')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  // Emergency contacts methods
  Future<void> addEmergencyContact({
    required String userId,
    required Map<String, dynamic> contactData,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    final userProfile = await getCompleteUserProfile(userId);
    if (userProfile != null) {
      final currentContacts = List<Map<String, dynamic>>.from(
        userProfile['emergency_contacts'] ?? [],
      );
      currentContacts.add(contactData);

      await updateUserProfileData(
        userId: userId,
        profileData: {'emergency_contacts': currentContacts},
      );
    }
  }

  Future<void> updateEmergencyContact({
    required String userId,
    required int contactIndex,
    required Map<String, dynamic> contactData,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    final userProfile = await getCompleteUserProfile(userId);
    if (userProfile != null) {
      final currentContacts = List<Map<String, dynamic>>.from(
        userProfile['emergency_contacts'] ?? [],
      );

      if (contactIndex < currentContacts.length) {
        currentContacts[contactIndex] = contactData;

        await updateUserProfileData(
          userId: userId,
          profileData: {'emergency_contacts': currentContacts},
        );
      }
    }
  }

  Future<void> deleteEmergencyContact({
    required String userId,
    required int contactIndex,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    final userProfile = await getCompleteUserProfile(userId);
    if (userProfile != null) {
      final currentContacts = List<Map<String, dynamic>>.from(
        userProfile['emergency_contacts'] ?? [],
      );

      if (contactIndex < currentContacts.length) {
        currentContacts.removeAt(contactIndex);

        await updateUserProfileData(
          userId: userId,
          profileData: {'emergency_contacts': currentContacts},
        );
      }
    }
  }

  // Medical history methods
  Future<void> addMedicalHistoryEntry({
    required String userId,
    required Map<String, dynamic> historyEntry,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    final userProfile = await getCompleteUserProfile(userId);
    if (userProfile != null) {
      final currentHistory = List<Map<String, dynamic>>.from(
        userProfile['medical_history'] ?? [],
      );
      currentHistory.add(historyEntry);

      await updateUserProfileData(
        userId: userId,
        profileData: {'medical_history': currentHistory},
      );
    }
  }

  // User preferences methods
  Future<void> updateUserPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    final userProfile = await getCompleteUserProfile(userId);
    if (userProfile != null) {
      final currentPreferences = Map<String, dynamic>.from(
        userProfile['preferences'] ?? {},
      );
      currentPreferences.addAll(preferences);

      await updateUserProfileData(
        userId: userId,
        profileData: {'preferences': currentPreferences},
      );
    }
  }

  // =====================================================
  // CONVERSATIONAL AI METHODS
  // =====================================================

  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? conversationId,
    required String? userId,
    Map<String, String>? location,
    Map<String, dynamic>? userProfile,
  }) async {
    print('=== SEND CHAT MESSAGE START ===');
    print('Message: $message');
    print('Conversation ID: $conversationId');
    print('User ID: $userId');
    print('Location: $location');
    print('User Profile: $userProfile');

    if (!_initialized) {
      print('❌ SupabaseService not initialized');
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    if (userId == null) {
      print('❌ User ID is null');
      throw Exception('User ID is required');
    }

    try {
      print('📡 Calling conversational_ai_edge_function Edge Function...');
      final response = await _supabase.functions.invoke(
        'conversational_ai_edge_function',
        body: {
          'conversation_id': conversationId,
          'user_id': userId,
          'message': message,
          'location': location,
          'user_profile': userProfile,
        },
      );

      print('📡 Edge Function Response Status: ${response.status}');
      print('📡 Edge Function Response Data: ${response.data}');

      if (response.status != 200) {
        print('❌ Edge Function failed with status: ${response.status}');
        print('❌ Error details: ${response.data}');
        throw Exception('Failed to send chat message: ${response.status}');
      }

      print('✅ Chat message sent successfully');
      print('=== SEND CHAT MESSAGE END ===');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      print('❌ Error sending chat message: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      print('=== SEND CHAT MESSAGE ERROR END ===');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    try {
      final response = await _supabase.rpc('get_user_conversations', params: {
        'p_user_id': userId,
        'p_limit': 10,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user conversations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getConversationWithMessages(
      String conversationId) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    try {
      final response =
          await _supabase.rpc('get_conversation_with_messages', params: {
        'p_conversation_id': conversationId,
      });

      if (response != null && response.isNotEmpty) {
        return Map<String, dynamic>.from(response[0]);
      }
      return null;
    } catch (e) {
      print('Error getting conversation with messages: $e');
      return null;
    }
  }

  Future<String> createNewConversation({
    required String userId,
    String title = 'Health Chat',
    String? stateCode,
    String? lgaCode,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    try {
      final response = await _supabase.rpc('create_conversation', params: {
        'p_user_id': userId,
        'p_title': title,
        'p_state_code': stateCode,
        'p_lga_code': lgaCode,
      });

      return response.toString();
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  // Clean up empty conversations (conversations with no messages)
  Future<void> cleanupEmptyConversations(String userId) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    try {
      // Get all conversations for the user
      final conversations = await getUserConversations(userId);

      for (final conversation in conversations) {
        if (conversation['total_messages'] == 0) {
          // Delete empty conversation
          await _supabase
              .from('conversations')
              .delete()
              .eq('id', conversation['id']);

          print('🗑️ Deleted empty conversation: ${conversation['id']}');
        }
      }
    } catch (e) {
      print('Error cleaning up empty conversations: $e');
    }
  }

  // Get user analytics data for profile screen
  Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    try {
      // Get user predictions
      final predictions = await getUserPredictions(userId);

      // Calculate analytics
      final totalPredictions = predictions.length;
      final criticalPredictions = predictions
          .where((p) =>
              p['prediction_data']?['urgency'] == 'critical' ||
              p['prediction_data']?['urgency'] == 'high' ||
              p['urgency'] == 'critical' ||
              p['urgency'] == 'high')
          .length;

      // Get common symptoms
      final commonSymptoms = <String, int>{};
      for (final prediction in predictions) {
        final symptoms = List<String>.from(prediction['symptoms'] ?? []);
        for (final symptom in symptoms) {
          commonSymptoms[symptom] = (commonSymptoms[symptom] ?? 0) + 1;
        }
      }

      final topSymptoms = commonSymptoms.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5);

      // Get conversations data
      final conversations = await getUserConversations(userId);
      final totalConversations = conversations.length;
      final conversationsWithPredictions =
          conversations.where((c) => c['has_prediction'] == true).length;

      return {
        'total_predictions': totalPredictions,
        'critical_predictions': criticalPredictions,
        'total_conversations': totalConversations,
        'conversations_with_predictions': conversationsWithPredictions,
        'top_symptoms': topSymptoms
            .map((e) => {'symptom': e.key, 'count': e.value})
            .toList(),
        'last_prediction':
            predictions.isNotEmpty ? predictions.first['created_at'] : null,
        'last_conversation': conversations.isNotEmpty
            ? conversations.first['last_message_at']
            : null,
      };
    } catch (e) {
      print('Error getting user analytics: $e');
      return {
        'total_predictions': 0,
        'critical_predictions': 0,
        'total_conversations': 0,
        'conversations_with_predictions': 0,
        'top_symptoms': [],
        'last_prediction': null,
        'last_conversation': null,
      };
    }
  }

  // =====================================================
  // MESSAGE FEEDBACK METHODS
  // =====================================================

  /// Add like/dislike feedback to an AI message
  Future<bool> addMessageFeedback({
    required String messageId,
    required String userId,
    required String feedback, // 'like' or 'dislike'
    String? comment,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    try {
      print('📝 Adding message feedback: $feedback');

      final result = await _supabase.rpc('add_message_feedback', params: {
        'p_message_id': messageId,
        'p_user_id': userId,
        'p_feedback': feedback,
        'p_comment': comment,
      });

      return result == true;
    } catch (e) {
      print('Error adding message feedback: $e');
      throw Exception('Failed to add feedback: $e');
    }
  }

  /// Get feedback statistics for a conversation
  Future<Map<String, dynamic>> getConversationFeedbackStats(
      String conversationId) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    try {
      final response = await _supabase.rpc('get_conversation_feedback_stats',
          params: {'p_conversation_id': conversationId});

      if (response.isNotEmpty) {
        return Map<String, dynamic>.from(response[0]);
      }
      return {
        'total_messages': 0,
        'liked_messages': 0,
        'disliked_messages': 0,
        'no_feedback_messages': 0,
        'like_percentage': 0.0,
      };
    } catch (e) {
      print('Error getting feedback stats: $e');
      return {
        'total_messages': 0,
        'liked_messages': 0,
        'disliked_messages': 0,
        'no_feedback_messages': 0,
        'like_percentage': 0.0,
      };
    }
  }

  /// Get user's feedback history
  Future<List<Map<String, dynamic>>> getUserFeedbackHistory(
    String userId, {
    int limit = 50,
  }) async {
    if (!_initialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }

    try {
      final response =
          await _supabase.rpc('get_user_feedback_history', params: {
        'p_user_id': userId,
        'p_limit': limit,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user feedback history: $e');
      return [];
    }
  }
}
