// =====================================================
// TAIMAKO CONVERSATIONAL AI EDGE FUNCTION
// =====================================================
// ✅ CONVERSATIONAL: ChatGPT-style health conversations
// ✅ CONTEXT AWARE: Remembers previous messages
// ✅ FOLLOW-UP: Asks clarifying questions
// ✅ NATURAL LANGUAGE: Extracts symptoms from conversation

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// GROQ API Configuration
const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "llama-3.3-70b-versatile";

// Supabase Configuration
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface ChatRequest {
  conversation_id?: string;
  user_id: string;
  message: string;
  location?: {
    state_code?: string;
    lga_code?: string;
  };
  user_profile?: {
    age_group?: string;
    gender?: string;
    occupation?: string;
    medical_history?: string[];
    current_medications?: string[];
  };
}

interface ChatResponse {
  success: boolean;
  conversation_id: string;
  message_id: string;
  response: {
    content: string;
    message_type: 'text' | 'prediction' | 'follow_up' | 'clarification';
    prediction_data?: any;
    follow_up_questions?: string[];
    confidence?: number;
    urgency?: string;
    severity?: string;
  };
  context?: {
    extracted_symptoms: string[];
    conversation_stage: string;
    needs_clarification: boolean;
  };
}

serve(async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("💬 Conversational AI request received");

    const {
      conversation_id,
      user_id,
      message,
      location,
      user_profile
    }: ChatRequest = await req.json();

    if (!user_id || !message) {
      return new Response(
        JSON.stringify({ error: "User ID and message are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Step 1: Get or create conversation
    let currentConversationId = conversation_id;
    if (!currentConversationId) {
      console.log("🆕 Creating new conversation");
      
      // Check for recent empty conversations (within last 5 minutes)
      const { data: recentConvos } = await supabase
        .from('conversations')
        .select('id, total_messages, created_at')
        .eq('user_id', user_id)
        .eq('total_messages', 0)
        .gte('created_at', new Date(Date.now() - 5 * 60 * 1000).toISOString())
        .order('created_at', { ascending: false })
        .limit(1);
      
      if (recentConvos && recentConvos.length > 0) {
        // Reuse the recent empty conversation
        currentConversationId = recentConvos[0].id;
        console.log("♻️ Reusing recent empty conversation:", currentConversationId);
        
        // Update the title
        await supabase
          .from('conversations')
          .update({ title: generateConversationTitle(message) })
          .eq('id', currentConversationId);
      } else {
        // Create new conversation
        const { data: newConvId, error: createError } = await supabase.rpc('create_conversation', {
          p_user_id: user_id,
          p_title: generateConversationTitle(message),
          p_state_code: location?.state_code,
          p_lga_code: location?.lga_code
        });

        if (createError) {
          console.error("❌ Error creating conversation:", createError);
          throw new Error(`Failed to create conversation: ${createError.message}`);
        }

        if (!newConvId) {
          throw new Error("Failed to create conversation: No ID returned");
        }

        currentConversationId = newConvId;
        console.log("✅ Created conversation:", currentConversationId);
      }
    }

    // Step 2: Get conversation context and history
    console.log("📚 Loading conversation context for:", currentConversationId);
    const { data: conversationData, error: fetchError } = await supabase.rpc('get_conversation_with_messages', {
      p_conversation_id: currentConversationId
    });

    if (fetchError) {
      console.error("❌ Error fetching conversation:", fetchError);
      throw new Error(`Failed to fetch conversation: ${fetchError.message}`);
    }

    const conversation = conversationData?.[0];
    if (!conversation) {
      console.error("❌ Conversation not found:", currentConversationId);
      throw new Error("Conversation not found");
    }

    console.log("✅ Loaded conversation with", conversation.total_messages, "messages");

    // Step 3: Get conversation context
    const { data: contextData } = await supabase
      .from('conversation_context')
      .select('*')
      .eq('conversation_id', currentConversationId)
      .single();

    console.log("✅ Loaded context, stage:", contextData?.conversation_stage || 'initial');

    // Step 4: Save user message
    console.log("💾 Saving user message");
    const { data: userMessageId, error: userMsgError } = await supabase.rpc('add_message', {
      p_conversation_id: currentConversationId,
      p_user_id: user_id,
      p_content: message,
      p_role: 'user',
      p_message_type: 'text'
    });

    if (userMsgError) {
      console.error("❌ Error saving user message:", userMsgError);
      throw new Error(`Failed to save user message: ${userMsgError.message}`);
    }

    console.log("✅ User message saved:", userMessageId);

    // Step 5: Process with AI
    console.log("🤖 Processing with conversational AI");
    const aiResponse = await processWithConversationalAI({
      message,
      conversationHistory: conversation.messages || [],
      context: contextData,
      userProfile: user_profile,
      location: location?.state_code
    });

    // Step 5.5: Check if we should make a prediction
    const messageCount = conversation.messages?.length || 0;
    const extractedSymptoms = aiResponse.extracted_symptoms || [];
    
    // Combine with context symptoms for better accuracy
    const allSymptoms = [
      ...extractedSymptoms,
      ...(contextData?.extracted_symptoms || [])
    ].filter((symptom, index, arr) => arr.indexOf(symptom) === index); // Remove duplicates
    
    const shouldPredict = aiResponse.should_predict || 
                          messageCount >= 4 || 
                          allSymptoms.length >= 3 ||
                          !aiResponse.needs_clarification;

    console.log(`📊 Decision: ${messageCount} messages, ${allSymptoms.length} symptoms [${allSymptoms.join(', ')}], should_predict: ${shouldPredict}`);

    // Step 5.6: Call predict-illness if conditions met
    let predictionResult = null;
    if (shouldPredict && allSymptoms.length > 0) {
      console.log("🔮 Triggering prediction with symptoms:", allSymptoms);
      try {
        const predictionResponse = await fetch(`${SUPABASE_URL}/functions/v1/predict-illness`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
          },
          body: JSON.stringify({
            symptoms: allSymptoms, // Use combined symptoms
            user_id: user_id,
            age_group: user_profile?.age_group,
            gender: user_profile?.gender,
            location: location
          })
        });

        if (predictionResponse.ok) {
          const predictionData = await predictionResponse.json();
          predictionResult = predictionData.result;
          
          // Update AI response with prediction
          aiResponse.message_type = 'prediction';
          aiResponse.prediction_data = predictionResult;
          aiResponse.content = generatePredictionMessage(predictionResult);
          
          console.log(`✅ Prediction completed: ${predictionResult.illness}`);
        } else {
          console.error("❌ Prediction failed:", await predictionResponse.text());
        }
      } catch (predError) {
        console.error("❌ Error calling predict-illness:", predError);
      }
    }

    // Step 6: Save AI response
    console.log("💾 Saving AI response");
    const { data: aiMessageId, error: aiMsgError } = await supabase.rpc('add_message', {
      p_conversation_id: currentConversationId,
      p_user_id: user_id,
      p_content: aiResponse.content,
      p_role: 'assistant',
      p_message_type: aiResponse.message_type,
      p_prediction_data: aiResponse.prediction_data,
      p_follow_up_questions: aiResponse.follow_up_questions
    });

    if (aiMsgError) {
      console.error("❌ Error saving AI message:", aiMsgError);
      throw new Error(`Failed to save AI message: ${aiMsgError.message}`);
    }

    console.log("✅ AI message saved:", aiMessageId);

    // Step 7: Update conversation context
    console.log("🧠 Updating conversation context");
    await updateConversationContext(supabase, currentConversationId, {
      newMessage: message,
      aiResponse: aiResponse,
      existingContext: contextData
    });

    console.log("✅ Conversational AI response completed");

    // Convert aiMessageId to string if it's not already
    const messageIdString = Array.isArray(aiMessageId) ? aiMessageId[0] : aiMessageId;
    
    const response: ChatResponse = {
      success: true,
      conversation_id: currentConversationId,
      message_id: messageIdString?.toString(),
      response: {
        content: aiResponse.content,
        message_type: aiResponse.message_type,
        prediction_data: aiResponse.prediction_data,
        follow_up_questions: aiResponse.follow_up_questions,
        confidence: aiResponse.confidence,
        urgency: aiResponse.urgency,
        severity: aiResponse.severity
      },
      context: {
        extracted_symptoms: aiResponse.extracted_symptoms || [],
        conversation_stage: aiResponse.conversation_stage || 'ongoing',
        needs_clarification: aiResponse.needs_clarification || false
      }
    };

    return new Response(
      JSON.stringify(response),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    );

  } catch (error) {
    console.error("❌ Error in conversational AI:", error);
    return new Response(
      JSON.stringify({
        error: error.message || "Internal server error",
        details: error.toString()
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    );
  }
});

// =====================================================
// CONVERSATIONAL AI PROCESSING
// =====================================================
async function processWithConversationalAI({
  message,
  conversationHistory,
  context,
  userProfile,
  location
}: {
  message: string;
  conversationHistory: any[];
  context: any;
  userProfile: any;
  location?: string;
}) {
  try {
    // Build conversation context for AI
    const conversationContext = buildConversationContext(conversationHistory, context);
    
    const systemPrompt = `You are Taimako, a Nigerian medical AI assistant specializing in conversational health consultations. You provide empathetic, culturally-sensitive health advice.

CONVERSATION CONTEXT:
${conversationContext}

CURRENT CONVERSATION STAGE: ${context?.conversation_stage || 'initial'}
MESSAGES IN CONVERSATION: ${conversationHistory.length}

CRITICAL DECISION RULES:
1. **ADVICE vs PREDICTION**: 
   - If user asks "how do I fix", "what should I do", "advice", "help" → Give ADVICE (message_type: "text")
   - If user describes symptoms asking "what's wrong", "what do I have" → Make PREDICTION (message_type: "prediction")
   - If user asks "is this serious" → Make PREDICTION with urgency assessment

2. **SYMPTOM EXTRACTION**: Extract ALL mentioned symptoms accurately:
   - "upper back aches" → ["upper_back_pain", "back_ache"]
   - "sitting too long" → ["poor_posture", "prolonged_sitting"]
   - "left side" → ["left_side_pain"]

3. **PREDICTION CRITERIA** (ONLY when appropriate):
   - User explicitly asks for diagnosis ("what's wrong", "what do I have", "diagnosis")
   - Multiple clear symptoms mentioned (at least 2-3 symptoms)
   - User asks "what's wrong with me" or similar diagnostic questions
   - Confidence must be >70% or don't predict - give advice instead
   - For back pain + sitting issues, suggest posture advice rather than UTI prediction

4. **ADVICE CRITERIA** (Most common):
   - User asks for help/advice
   - Lifestyle/behavioral questions
   - Prevention questions
   - General health guidance
   - Back pain from sitting → posture and ergonomics advice
   - Neck pain from work → stretching and workstation setup advice

5. **LANGUAGE RULE**: Always respond in clear, professional English. Do NOT use Nigerian Pidgin unless the user specifically requests it.

6. **ACCURACY RULE**: Only make predictions when confidence is >70%. If confidence is low, provide general health advice instead.

RESPONSE FORMAT:
Return ONLY valid JSON in this exact format:
{
  "content": "Your response message",
  "message_type": "text|prediction|follow_up|clarification",
  "extracted_symptoms": ["symptom1", "symptom2"],
  "conversation_stage": "initial|symptom_collection|clarification|prediction|follow_up",
  "needs_clarification": true|false,
  "follow_up_questions": ["question1"],
  "prediction_data": {
    "illness": "condition name",
    "confidence": 0.85,
    "urgency": "low|moderate|high|critical",
    "severity": "mild|moderate|severe|critical",
    "advice": "detailed advice",
    "prevention_tips": ["tip1", "tip2"],
    "follow_up_advice": ["advice1", "advice2"]
  }
}`;

    const userPrompt = `User message: "${message}"

User Profile: 
- Age: ${userProfile?.age_group || 'not specified'}
- Gender: ${userProfile?.gender || 'not specified'}
- Occupation: ${userProfile?.occupation || 'not specified'}
- Location: ${location || 'Nigeria'}

Previous conversation (${conversationHistory.length} messages):
${conversationHistory.slice(-5).map(m => `${m.role}: ${m.content}`).join('\n')}

Current context:
- Extracted symptoms: ${context?.extracted_symptoms?.join(', ') || 'None yet'}
- Current concerns: ${context?.current_concerns?.join(', ') || 'None yet'}
- Conversation stage: ${context?.conversation_stage || 'initial'}

ANALYZE THE USER'S INTENT:
- Does the user ask "how do I fix", "what should I do", "advice", "help"? → Give ADVICE (message_type: "text")
- Does the user ask "what's wrong", "what do I have", "diagnosis"? → Make PREDICTION (message_type: "prediction")
- Does the user describe symptoms without asking for diagnosis? → Give ADVICE (message_type: "text")

EXTRACT SYMPTOMS ACCURATELY:
- Look for ALL health-related terms in the message
- Convert to standard symptom names
- Include location, severity, duration if mentioned

Respond as Taimako. Be helpful and accurate!`;

    const response = await fetch(GROQ_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${GROQ_API_KEY}`
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt }
        ],
        temperature: 0.3, // Lower temperature for more consistent, professional responses
        max_tokens: 1000,
        response_format: { type: "json_object" }
      })
    });

    if (!response.ok) {
      throw new Error(`Groq API error: ${response.status}`);
    }

    const data = await response.json();
    const aiResponse = JSON.parse(data.choices[0].message.content);

    console.log("🤖 AI Response:", aiResponse.content?.substring(0, 100));

    return {
      content: aiResponse.content || "I understand you're not feeling well. Can you tell me more about your symptoms?",
      message_type: aiResponse.message_type || 'text',
      extracted_symptoms: aiResponse.extracted_symptoms || [],
      conversation_stage: aiResponse.conversation_stage || 'ongoing',
      needs_clarification: aiResponse.needs_clarification !== undefined ? aiResponse.needs_clarification : true,
      should_predict: aiResponse.should_predict || false,
      follow_up_questions: aiResponse.follow_up_questions ? aiResponse.follow_up_questions.slice(0, 1) : [], // MAX 1 question
      prediction_data: aiResponse.prediction_data || null,
      confidence: aiResponse.prediction_data?.confidence,
      urgency: aiResponse.prediction_data?.urgency,
      severity: aiResponse.prediction_data?.severity
    };

  } catch (error) {
    console.error("❌ AI processing error:", error);
    return {
      content: "I'm sorry, I'm having trouble processing your message right now. Can you please try again?",
      message_type: 'text',
      extracted_symptoms: [],
      conversation_stage: 'ongoing',
      needs_clarification: false,
      follow_up_questions: [],
      prediction_data: null
    };
  }
}

// =====================================================
// HELPER FUNCTIONS
// =====================================================

function generatePredictionMessage(prediction: any): string {
  // Use simple English, not Pidgin
  const advice = prediction.advice || "Please rest, stay hydrated, and follow medical advice.";
  
  return `Based on your symptoms, you likely have **${prediction.illness}** (${(prediction.confidence * 100).toFixed(0)}% confidence).

${advice}

**Urgency Level:** ${prediction.urgency.toUpperCase()}
**Severity:** ${prediction.severity}

Please monitor your symptoms closely. If they worsen or don't improve within 2-3 days, visit a doctor immediately. 🏥`;
}

function buildConversationContext(history: any[], context: any): string {
  let contextStr = "CONVERSATION HISTORY:\n";
  
  if (history && history.length > 0) {
    history.slice(-10).forEach(msg => { // Last 10 messages
      contextStr += `${msg.role}: ${msg.content}\n`;
    });
  }
  
  if (context) {
    contextStr += `\nEXTRACTED SYMPTOMS: ${context.extracted_symptoms?.join(', ') || 'None'}\n`;
    contextStr += `CURRENT CONCERNS: ${context.current_concerns?.join(', ') || 'None'}\n`;
    contextStr += `CONVERSATION STAGE: ${context.conversation_stage || 'initial'}\n`;
  }
  
  return contextStr;
}

function generateConversationTitle(message: string): string {
  const lowerMessage = message.toLowerCase();
  
  // Extract key symptoms/topics
  const symptomPatterns = {
    'fever': ['fever', 'hot body', 'temperature'],
    'headache': ['headache', 'head pain', 'migraine'],
    'cough': ['cough', 'coughing'],
    'cold': ['cold', 'flu', 'runny nose'],
    'malaria': ['malaria'],
    'typhoid': ['typhoid'],
    'stomach': ['stomach', 'belly', 'abdominal'],
    'chest': ['chest pain', 'chest'],
    'body pain': ['body pain', 'body ache', 'muscle pain'],
    'diarrhea': ['diarrhea', 'stooling', 'running stomach'],
    'vomiting': ['vomit', 'vomiting', 'throwing up'],
    'dizziness': ['dizzy', 'dizziness'],
    'weakness': ['weak', 'weakness', 'tired', 'fatigue']
  };
  
  // Find matching symptoms
  const foundSymptoms: string[] = [];
  for (const [symptom, patterns] of Object.entries(symptomPatterns)) {
    if (patterns.some(pattern => lowerMessage.includes(pattern))) {
      foundSymptoms.push(symptom);
    }
  }
  
  // Generate title based on symptoms
  if (foundSymptoms.length === 0) {
    // No specific symptoms, use timestamp
    const now = new Date();
    const time = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: true });
    return `Health Chat - ${time}`;
  } else if (foundSymptoms.length === 1) {
    // Single symptom
    return `${capitalize(foundSymptoms[0])} Issue`;
  } else if (foundSymptoms.length === 2) {
    // Two symptoms
    return `${capitalize(foundSymptoms[0])} & ${capitalize(foundSymptoms[1])}`;
  } else {
    // Multiple symptoms - pick top 2 most important
    const important = foundSymptoms
      .filter(s => ['fever', 'chest', 'headache', 'malaria', 'typhoid'].includes(s))
      .slice(0, 2);
    
    if (important.length >= 2) {
      return `${capitalize(important[0])} & ${capitalize(important[1])}`;
    } else if (important.length === 1) {
      return `${capitalize(important[0])} & ${capitalize(foundSymptoms.find(s => s !== important[0]) || 'Other')}`;
    } else {
      // Fallback to first 2
      return `${capitalize(foundSymptoms[0])} & ${capitalize(foundSymptoms[1])}`;
    }
  }
}

function capitalize(text: string): string {
  return text.split(' ')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

async function updateConversationContext(supabase: any, conversationId: string, data: any) {
  try {
    const { newMessage, aiResponse, existingContext } = data;
    
    // Extract symptoms from the new message
    const extractedSymptoms = extractSymptomsFromText(newMessage);
    
    // Combine with AI-extracted symptoms
    const aiSymptoms = aiResponse.extracted_symptoms || [];
    
    // Merge all symptoms
    const allSymptoms = [
      ...(existingContext?.extracted_symptoms || []),
      ...extractedSymptoms,
      ...aiSymptoms
    ].filter((symptom, index, arr) => arr.indexOf(symptom) === index); // Remove duplicates
    
    console.log(`🧠 Updating context with ${allSymptoms.length} total symptoms: ${allSymptoms.join(', ')}`);
    
    // Update context
    const updatedContext = {
      extracted_symptoms: allSymptoms,
      current_concerns: existingContext?.current_concerns || [],
      conversation_stage: aiResponse.conversation_stage || existingContext?.conversation_stage || 'ongoing',
      
      // Add new symptoms to concerns if this is a prediction
      ...(aiResponse.message_type === 'prediction' && {
        current_concerns: [
          ...(existingContext?.current_concerns || []),
          aiResponse.prediction_data?.illness
        ].filter(Boolean)
      })
    };

    await supabase
      .from('conversation_context')
      .upsert({
        conversation_id: conversationId,
        ...updatedContext,
        updated_at: new Date().toISOString()
      });

  } catch (error) {
    console.error("❌ Error updating context:", error);
  }
}

function extractSymptomsFromText(text: string): string[] {
  const commonSymptoms = [
    // General symptoms
    'fever', 'headache', 'cough', 'dry cough', 'fatigue', 'nausea', 'vomiting', 'diarrhea',
    'abdominal pain', 'chest pain', 'shortness of breath', 'dizziness',
    'muscle pain', 'joint pain', 'sore throat', 'runny nose', 'sneezing',
    'congestion', 'chills', 'sweating', 'weakness', 'loss of appetite',
    'weight loss', 'blurred vision', 'rash', 'swelling', 'redness',
    'itchiness', 'burning sensation', 'frequent urination', 'blood in urine',
    'pale skin', 'jaundice', 'body ache', 'body pain', 'tired', 'exhausted',
    'sick', 'unwell', 'pain', 'cold', 'flu', 'malaria', 'typhoid',
    'migraine', 'chest discomfort',
    
    // Back and spine symptoms
    'back pain', 'back ache', 'upper back', 'lower back', 'middle back',
    'spine pain', 'spinal pain', 'backache', 'back stiffness',
    'neck pain', 'shoulder pain', 'shoulder ache',
    
    // Posture and lifestyle related
    'poor posture', 'sitting too long', 'prolonged sitting', 'bad posture',
    'desk work', 'computer work', 'office work',
    
    // Location specific
    'left side', 'right side', 'left side pain', 'right side pain',
    'upper left', 'upper right', 'lower left', 'lower right',
    
    // Severity indicators
    'badly', 'severely', 'mildly', 'moderately', 'intensely',
    'sharp pain', 'dull pain', 'throbbing pain', 'stabbing pain',
    'burning pain', 'aching pain', 'stiffness', 'tension'
  ];

  const lowerText = text.toLowerCase();
  const found = commonSymptoms.filter(symptom => lowerText.includes(symptom));
  
  // Additional pattern matching for compound symptoms
  const patterns = [
    { pattern: /upper back.*ache|back.*ache.*upper/i, symptom: 'upper_back_pain' },
    { pattern: /left side.*pain|pain.*left side/i, symptom: 'left_side_pain' },
    { pattern: /sitting.*too long|too long.*sitting/i, symptom: 'prolonged_sitting' },
    { pattern: /poor.*posture|bad.*posture/i, symptom: 'poor_posture' },
    { pattern: /back.*pain|back.*ache/i, symptom: 'back_pain' },
  ];
  
  for (const { pattern, symptom } of patterns) {
    if (pattern.test(text) && !found.includes(symptom)) {
      found.push(symptom);
    }
  }
  
  // Log for debugging
  console.log(`🔍 Extracted symptoms from "${text.substring(0, 50)}...": ${found.join(', ')}`);
  
  return found;
}