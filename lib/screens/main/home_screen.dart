import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/health_prediction_service.dart';
import '../../services/supabase_service.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialLoading = true; // Loading state for initial data
  Map<String, dynamic>? _userProfile;
  String _userName = 'User';
  List<Map<String, dynamic>> _recentConversations = [];
  String? _currentConversationId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadRecentConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      await supabaseService.signOut();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecentConversations() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId != null) {
        // Clean up empty conversations first
        await supabaseService.cleanupEmptyConversations(userId);

        final conversations =
            await supabaseService.getUserConversations(userId);

        // Filter out empty conversations (no messages or only welcome messages)
        final validConversations = conversations.where((conv) {
          return conv['total_messages'] != null && conv['total_messages'] > 0;
        }).toList();

        setState(() {
          _recentConversations = validConversations.take(3).toList();
        });

        print('📋 Loaded ${validConversations.length} valid conversations');
      }
    } catch (e) {
      print('❌ Error loading conversations: $e');
      // Error loading conversations - will show empty list
    }
  }

  Future<void> _refreshConversations() async {
    print('🔄 Pull to refresh triggered');
    try {
      // Reload recent conversations
      await _loadRecentConversations();

      // Optional: Reload user profile if needed
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;
      if (userId != null) {
        final profile = await supabaseService.getCompleteUserProfile(userId);
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _userName = profile?['first_name'] ?? 'User';
          });
        }
      }

      print('✅ Conversations refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing conversations: $e');
    }
  }

  void _startNewChat() {
    print('🆕 Starting new chat...');
    setState(() {
      _messages.clear();
      _currentConversationId = null; // Reset conversation ID
      _addWelcomeMessage();
    });
    print('✅ New chat started, conversation ID reset');
  }

  Future<void> _loadUserProfile() async {
    print('=== LOAD USER PROFILE START ===');

    if (mounted) {
      setState(() {
        _isInitialLoading = true;
      });
    }

    // Add welcome messages immediately
    _addWelcomeMessage();

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      print('📡 Current user ID: $userId');

      if (userId != null) {
        print('📡 Loading user profile...');
        final profile = await supabaseService.getCompleteUserProfile(userId);
        print('📡 Profile loaded: $profile');

        if (mounted) {
          setState(() {
            _userProfile = profile;
            _userName = profile?['first_name'] ?? 'User';
            _isInitialLoading = false;
          });
        }

        print('📡 User name set to: $_userName');
        print('📡 Profile state: ${profile?['state_name']}');
        print('📡 Profile LGA: ${profile?['lga_code']}');
      } else {
        print('❌ No user ID available');
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
          });
        }
      }

      print('✅ User profile loaded successfully');
    } catch (e) {
      print('❌ Error loading user profile: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
    print('=== LOAD USER PROFILE END ===');
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: "Hi $_userName",
      isUser: false,
      timestamp: DateTime.now(),
      isGreeting: true,
    ));
    _messages.add(ChatMessage(
      text: "How are you feeling today?",
      isUser: false,
      timestamp: DateTime.now(),
      isGreeting: true,
    ));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    print('=== SEND MESSAGE START ===');
    print('Message text: $text');
    print('Is loading: $_isLoading');
    print('Current conversation ID: $_currentConversationId');

    if (text.isEmpty || _isLoading) {
      print('❌ Message empty or already loading');
      return;
    }

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Use conversational AI service
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      print('📡 Getting SupabaseService instance...');
      print('📡 Current user: ${supabaseService.currentUser?.id}');

      // Get user location data
      Map<String, String>? location;
      if (_userProfile?['state_name'] != null) {
        location = {
          'state_code': _userProfile!['state_code'] ?? 'LAG',
          'lga_code': _userProfile!['lga_code'],
        };
        print('📍 Location data: $location');
      } else {
        print('📍 No location data available');
      }

      // Call conversational AI
      print('🤖 Calling sendChatMessage...');
      final result = await supabaseService.sendChatMessage(
        message: text,
        conversationId: _currentConversationId,
        userId: supabaseService.currentUser?.id,
        location: location,
        userProfile: {
          'age_group': _userProfile?['age_group'],
          'gender': _userProfile?['gender'],
          'occupation': _userProfile?['occupation'],
        },
      );

      print('🤖 Chat message result: $result');

      // Update conversation ID if this is a new conversation
      if (_currentConversationId == null && result['conversation_id'] != null) {
        print('🆕 New conversation created: ${result['conversation_id']}');
        setState(() {
          _currentConversationId = result['conversation_id'];
        });
      }

      // Simulate typing delay
      print('⏳ Simulating typing delay...');
      await Future.delayed(const Duration(seconds: 2));

      // Add AI response
      print('💬 Adding AI response to chat...');
      setState(() {
        final response = result['response'] as Map<String, dynamic>;
        _messages.add(ChatMessage(
          text: response['content'],
          isUser: false,
          timestamp: DateTime.now(),
          isPrediction: response['message_type'] == 'prediction',
          predictionData: response['prediction_data'],
          followUpQuestions: response['follow_up_questions'] != null
              ? List<String>.from(response['follow_up_questions'])
              : null,
          messageId: result['message_id']
              ?.toString(), // Get message ID from top-level result
        ));
        _isLoading = false;
      });

      // Refresh recent conversations
      print('🔄 Refreshing recent conversations...');
      _loadRecentConversations();

      print('✅ Message sent successfully');
      print('=== SEND MESSAGE END ===');
    } catch (e) {
      print('❌ Error in _sendMessage: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');

      setState(() {
        _messages.add(ChatMessage(
          text:
              "I'm sorry, I'm having trouble processing your request right now. Please try again in a moment.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      print('=== SEND MESSAGE ERROR END ===');
    }

    _scrollToBottom();
  }

  Future<void> _handleMessageFeedback(String messageId, String feedback) async {
    try {
      print('📝 Processing feedback: $feedback for message: $messageId');

      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userId = supabaseService.currentUser?.id;

      if (userId == null) {
        print('❌ No user ID available for feedback');
        return;
      }

      final success = await supabaseService.addMessageFeedback(
        messageId: messageId,
        userId: userId,
        feedback: feedback,
      );

      if (success) {
        print('✅ Feedback saved successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(feedback == 'like'
                  ? 'Thank you for your feedback!'
                  : 'We appreciate your feedback and will improve!'),
              backgroundColor: const Color(0xFF00D4AA),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error saving feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save feedback. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<String> _extractSymptoms(String text) {
    // Simple keyword extraction - in production, you'd use NLP
    final commonSymptoms = [
      'fever',
      'headache',
      'cough',
      'fatigue',
      'nausea',
      'vomiting',
      'diarrhea',
      'abdominal pain',
      'chest pain',
      'shortness of breath',
      'dizziness',
      'muscle pain',
      'joint pain',
      'sore throat',
      'runny nose',
      'sneezing',
      'congestion',
      'chills',
      'sweating',
      'weakness',
      'loss of appetite',
      'weight loss',
      'blurred vision',
      'rash',
      'swelling',
      'redness',
      'itchiness',
      'burning sensation',
      'frequent urination',
      'blood in urine',
      'pale skin',
      'jaundice',
      'body ache',
      'body pain',
      'tired',
      'exhausted',
      'sick',
      'unwell',
      'pain'
    ];

    final lowerText = text.toLowerCase();
    return commonSymptoms
        .where((symptom) => lowerText.contains(symptom))
        .toList();
  }

  String _formatPredictionResponse(HealthPredictionResult result) {
    if (!result.hasPrediction) {
      return "I understand you're not feeling well. Could you please describe your symptoms in more detail? For example, you could mention specific symptoms like fever, headache, cough, etc.";
    }

    final prediction = result.prediction!;
    // Since 'prediction' is a Map<String, dynamic>, access the first entry
    final primaryPrediction = (prediction.values.first);

    String response =
        "Thanks for sharing that, $_userName. Based on your symptoms";

    // Add location context if available
    if (_userProfile?['state_name'] != null) {
      response += " and considering you're in ${_userProfile!['state_name']}";
    }

    response += ", you may have **${primaryPrediction.conditionName}** ";
    response += "(Confidence: ${primaryPrediction.confidencePercentage}).\n\n";

    response += "**Advice:** ${primaryPrediction.advice}\n\n";

    // Add location-specific emergency info if available
    if (_userProfile?['emergency_services'] != null) {
      response +=
          "**Emergency Contact:** ${_userProfile!['emergency_services']}\n\n";
    }

    if (primaryPrediction.urgency == 'critical' ||
        primaryPrediction.urgency == 'high') {
      response +=
          "⚠️ **Important:** This condition requires prompt medical attention. Please seek medical care immediately.\n\n";
    }

    response += "Do you also have any of these symptoms?\n";
    response += "- Nausea or vomiting\n";
    response += "- Chills\n";
    response += "- Fatigue\n";
    response += "- Body pain\n\n";

    response +=
        "*Remember: This is an AI assistant and not a replacement for professional medical advice. Please consult a healthcare provider for proper diagnosis and treatment.*";

    return response;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: const Color(0xFF2C2C2E),
              size: 24.sp,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          children: [
            Text(
              'Taimako',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C2C2E),
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              'Your Every Day Health Companion',
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF8E8E93),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              // Chat Messages
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshConversations,
                  color: const Color(0xFF00D4AA),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }

                      final message = _messages[index];
                      return ChatBubble(
                        message: message,
                        userName: _userName,
                        onFeedback: _handleMessageFeedback,
                      );
                    },
                  ),
                ),
              ),

              // Input Area
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: const Color(0xFF2C2C2E), // Black text color
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Kindly tell us how you are feeling...',
                            hintStyle: TextStyle(
                              fontSize: 16.sp,
                              color: const Color(0xFF8E8E93),
                              fontFamily: 'Poppins',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: _isLoading ? null : _sendMessage,
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF00D4AA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Loading Overlay
          if (_isInitialLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60.w,
                      height: 60.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Loading your profile...',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: const Color(0xFF8E8E93),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app logo.png',
                width: 32.w,
                height: 32.w,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                SizedBox(width: 4.w),
                _buildTypingDot(1),
                SizedBox(width: 4.w),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: const Color(0xFF8E8E93),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Taimako',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C2C2E),
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your Health Companion',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF8E8E93),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: [
                _buildDrawerItem(
                  icon: Icons.add,
                  title: 'New Chat',
                  onTap: () {
                    Navigator.pop(context);
                    _startNewChat();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chats',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistoryScreen()),
                    );
                  },
                ),

                SizedBox(height: 24.h),

                // Recent Chats Section
                Text(
                  'Recent',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C2C2E),
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 16.h),

                // Show real recent conversations
                if (_recentConversations.isNotEmpty) ...[
                  ..._recentConversations.map((conversation) {
                    return _buildRecentChatItem(
                      conversation['title'] ?? 'Health Chat',
                      conversation,
                    );
                  }),
                ] else ...[
                  _buildRecentChatItem('No recent conversations'),
                ],
              ],
            ),
          ),

          // User Profile and Logout
          Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildDrawerItem(
                  icon: Icons.person,
                  title: _userProfile?['first_name'] != null &&
                          _userProfile?['last_name'] != null
                      ? '${_userProfile!['first_name']} ${_userProfile!['last_name']}'
                      : _userName,
                  isProfile: true,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
                SizedBox(height: 8.h),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  isLogout: true,
                  onTap: () async {
                    Navigator.pop(context);
                    await _logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractIllnessFromPrediction(Map<String, dynamic> prediction) {
    try {
      final predictionData = prediction['prediction_data'];
      if (predictionData is String) {
        final parsed = Map<String, dynamic>.from(
            Map<String, dynamic>.from({'data': predictionData})['data'] ?? {});
        return parsed['illness'] ?? 'Unknown';
      } else if (predictionData is Map) {
        return predictionData['illness'] ?? 'Unknown';
      }
    } catch (e) {
      // Error parsing prediction data
    }
    return 'Unknown';
  }

  String _formatPredictionTitle(List<String> symptoms, String illness) {
    if (symptoms.isEmpty) return illness;

    final symptomText = symptoms.length > 2
        ? '${symptoms.take(2).join(', ')} and ${symptoms.length - 2} more'
        : symptoms.join(', ');

    return '$illness - $symptomText';
  }

  void _loadConversationIntoChat(Map<String, dynamic> conversation) async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      // Load conversation messages
      final conversationData =
          await supabaseService.getConversationWithMessages(conversation['id']);

      if (conversationData != null && conversationData['messages'] != null) {
        setState(() {
          _messages.clear();
          _currentConversationId = conversation['id'];

          // Add messages from conversation
          for (final msg in conversationData['messages']) {
            _messages.add(ChatMessage(
              text: msg['content'],
              isUser: msg['role'] == 'user',
              timestamp: DateTime.parse(msg['timestamp']),
              isPrediction: msg['message_type'] == 'prediction',
              predictionData: msg['prediction_data'],
              followUpQuestions: msg['follow_up_questions'] != null
                  ? List<String>.from(msg['follow_up_questions'])
                  : null,
            ));
          }
        });
      }
    } catch (e) {
      print('Error loading conversation: $e');
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isProfile = false,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: isProfile
              ? const Color(0xFF00D4AA)
              : isLogout
                  ? Colors.red.withOpacity(0.1)
                  : const Color(0xFFF2F2F7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16.sp,
          color: isProfile
              ? Colors.white
              : isLogout
                  ? Colors.red
                  : const Color(0xFF8E8E93),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          color: const Color(0xFF2C2C2E),
          fontFamily: 'Poppins',
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16.sp,
        color: const Color(0xFF8E8E93),
      ),
      onTap: onTap,
    );
  }

  Widget _buildRecentChatItem(String title,
      [Map<String, dynamic>? prediction]) {
    return ListTile(
      leading: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.chat_bubble_outline,
          size: 16.sp,
          color: const Color(0xFF8E8E93),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          color: const Color(0xFF2C2C2E),
          fontFamily: 'Poppins',
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14.sp,
        color: const Color(0xFF8E8E93),
      ),
      onTap: () {
        Navigator.pop(context);
        if (prediction != null) {
          // Load the conversation into chat
          _loadConversationIntoChat(prediction);
        }
      },
    );
  }
}

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final String userName;
  final Function(String, String)? onFeedback; // Callback for feedback

  const ChatBubble({
    super.key,
    required this.message,
    required this.userName,
    this.onFeedback,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: widget.message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.message.isUser) ...[
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app logo.png',
                  width: 32.w,
                  height: 32.w,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: widget.message.isUser
                    ? const Color(0xFF00D4AA)
                    : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: widget.message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: widget.message.isUser
                            ? Colors.white
                            : const Color(0xFF2C2C2E),
                        fontFamily: 'Poppins',
                        fontSize: 16.sp,
                        height: 1.4,
                      ),
                      h1: TextStyle(
                        color: widget.message.isUser
                            ? Colors.white
                            : const Color(0xFF2C2C2E),
                        fontFamily: 'Poppins',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      h2: TextStyle(
                        color: widget.message.isUser
                            ? Colors.white
                            : const Color(0xFF2C2C2E),
                        fontFamily: 'Poppins',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      h3: TextStyle(
                        color: widget.message.isUser
                            ? Colors.white
                            : const Color(0xFF2C2C2E),
                        fontFamily: 'Poppins',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      strong: TextStyle(
                        color: widget.message.isUser
                            ? Colors.white
                            : const Color(0xFF2C2C2E),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                      em: TextStyle(
                        color: widget.message.isUser
                            ? Colors.white
                            : const Color(0xFF2C2C2E),
                        fontFamily: 'Poppins',
                        fontStyle: FontStyle.italic,
                      ),
                      listBullet: TextStyle(
                        color: widget.message.isUser
                            ? Colors.white
                            : const Color(0xFF2C2C2E),
                        fontFamily: 'Poppins',
                        fontSize: 16.sp,
                      ),
                      listBulletPadding: EdgeInsets.only(right: 8.w),
                    ),
                    selectable: true,
                  ),
                  if (widget.message.isPrediction) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: widget.message.isUser
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFF00D4AA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'AI Prediction',
                        style: TextStyle(
                          color: widget.message.isUser
                              ? Colors.white
                              : const Color(0xFF00D4AA),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],

                  // Like/Dislike buttons for AI messages only
                  if (!widget.message.isUser && !widget.message.isGreeting) ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (widget.message.messageId != null &&
                                widget.onFeedback != null) {
                              widget.onFeedback!(
                                  widget.message.messageId!, 'like');
                              setState(() {
                                widget.message.userFeedback = 'like';
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: widget.message.userFeedback == 'like'
                                  ? const Color(0xFF00D4AA)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: widget.message.userFeedback == 'like'
                                    ? const Color(0xFF00D4AA)
                                    : const Color(0xFFE5E5EA),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.thumb_up_outlined,
                                  size: 14.sp,
                                  color: widget.message.userFeedback == 'like'
                                      ? Colors.white
                                      : const Color(0xFF8E8E93),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Helpful',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: widget.message.userFeedback == 'like'
                                        ? Colors.white
                                        : const Color(0xFF8E8E93),
                                    fontFamily: 'Poppins',
                                    fontWeight:
                                        widget.message.userFeedback == 'like'
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () {
                            print('🔘 Not helpful button tapped');
                            print('🔘 Message ID: ${widget.message.messageId}');
                            print(
                                '🔘 onFeedback callback: ${widget.onFeedback != null}');
                            if (widget.message.messageId != null &&
                                widget.onFeedback != null) {
                              print(
                                  '🔘 Calling feedback callback with messageId: ${widget.message.messageId}');
                              widget.onFeedback!(
                                  widget.message.messageId!, 'dislike');
                              setState(() {
                                widget.message.userFeedback = 'dislike';
                              });
                            } else {
                              print(
                                  '❌ Cannot save feedback: messageId=${widget.message.messageId}, onFeedback=${widget.onFeedback != null}');
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: widget.message.userFeedback == 'dislike'
                                  ? Colors.red
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: widget.message.userFeedback == 'dislike'
                                    ? Colors.red
                                    : const Color(0xFFE5E5EA),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.thumb_down_outlined,
                                  size: 14.sp,
                                  color:
                                      widget.message.userFeedback == 'dislike'
                                          ? Colors.white
                                          : const Color(0xFF8E8E93),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Not helpful',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color:
                                        widget.message.userFeedback == 'dislike'
                                            ? Colors.white
                                            : const Color(0xFF8E8E93),
                                    fontFamily: 'Poppins',
                                    fontWeight:
                                        widget.message.userFeedback == 'dislike'
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (widget.message.isUser) ...[
            SizedBox(width: 8.w),
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: const Color(0xFF2C2C2E),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isPrediction;
  final bool isGreeting;
  final dynamic predictionData;
  final List<String>? followUpQuestions;
  final String? messageId;
  String? userFeedback; // 'like', 'dislike', or null

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isPrediction = false,
    this.isGreeting = false,
    this.predictionData,
    this.followUpQuestions,
    this.messageId,
    this.userFeedback,
  });
}
