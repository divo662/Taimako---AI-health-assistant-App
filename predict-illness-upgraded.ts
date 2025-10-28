// =====================================================
// TAIMAKO EDGE FUNCTION: predict-illness (UPGRADED)
// =====================================================
// Enhanced prediction with location-based analysis,
// emergency detection, expanded dataset, and advanced AI integration

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// GROQ API Configuration
const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "llama-3.3-70b-versatile";

// Supabase Configuration
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface EnhancedPredictionRequest {
  symptoms: string[];
  user_id: string;
  age_group?: string;
  gender?: string;
  season?: string;
  location?: {
    state_code: string;
    lga_code?: string;
    coordinates?: { lat: number; lng: number };
  };
  additional_context?: {
    recent_travel?: string[];
    exposure_risks?: string[];
    current_medications?: string[];
    allergies?: string[];
  };
}

interface EnhancedPredictionResult {
  illness: string;
  confidence: number;
  urgency: string;
  severity: string;
  matched_symptoms: string[];
  advice: string;
  alternative_diagnoses: Array<{
    illness: string;
    confidence: number;
  }>;
  location_risk_factors: {
    state_risk: number;
    regional_prevalence: string;
    seasonal_factors: string[];
  };
  emergency_assessment: {
    is_critical: boolean;
    emergency_protocols: string[];
    emergency_contacts: any;
  };
  prevention_tips: string[];
  follow_up_advice: string[];
}

serve(async (req) => {
  // CORS Headers
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("🔍 Enhanced prediction request received");

    const {
      symptoms,
      user_id,
      age_group,
      gender,
      season,
      location,
      additional_context,
    }: EnhancedPredictionRequest = await req.json();

    if (!symptoms || symptoms.length === 0) {
      return new Response(
        JSON.stringify({ error: "Symptoms are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: "User ID is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`🩺 Processing enhanced prediction for user: ${user_id}`);
    console.log(`📋 Symptoms: ${symptoms.join(", ")}`);
    console.log(`📍 Location: ${location?.state_code || "Not provided"}`);

    // Initialize Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Step 1: Get user's location from profile if not provided
    let userLocation = location;
    if (!userLocation) {
      console.log("📍 Getting user location from profile...");
      const { data: profile } = await supabase
        .from("user_profiles")
        .select("profile_data")
        .eq("user_id", user_id)
        .single();

      if (profile?.profile_data) {
        const profileData = profile.profile_data as any;
        userLocation = {
          state_code: profileData.state_code,
          lga_code: profileData.lga_code,
        };
        console.log(`📍 Found user location: ${profileData.state_name} (${profileData.state_code})`);
      }
    }

    // Step 2: Check for critical conditions first
    console.log("🚨 Checking for critical conditions...");
    const { data: criticalCheck } = await supabase.rpc(
      "check_critical_condition",
      {
        p_symptoms: symptoms,
        p_user_location: userLocation?.state_code,
      }
    );

    if (criticalCheck?.is_critical) {
      console.log("🚨 CRITICAL CONDITION DETECTED!");
      return new Response(
        JSON.stringify({
          success: true,
          prediction_id: `critical_${Date.now()}`,
          result: {
            illness: "CRITICAL CONDITION",
            confidence: 1.0,
            urgency: "critical",
            severity: "high",
            matched_symptoms: symptoms,
            advice: "SEEK IMMEDIATE MEDICAL ATTENTION - CRITICAL CONDITION DETECTED",
            alternative_diagnoses: [],
            location_risk_factors: {
              state_risk: 1.0,
              regional_prevalence: "critical",
              seasonal_factors: [],
            },
            emergency_assessment: criticalCheck,
            prevention_tips: ["Call emergency services immediately"],
            follow_up_advice: ["Do not delay medical attention"],
          },
          message: "CRITICAL CONDITION DETECTED - EMERGENCY PROTOCOLS ACTIVATED",
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 3: Get location-based predictions
    console.log("📍 Getting location-based predictions...");
    const { data: locationPredictions } = await supabase.rpc(
      "get_location_based_prediction",
      {
        p_symptoms: symptoms,
        p_state_code: userLocation?.state_code || "LAG",
        p_lga_code: userLocation?.lga_code,
        p_season: season || "year_round",
      }
    );

    // Step 4: Get emergency services for location
    console.log("🚨 Getting emergency services...");
    const { data: emergencyServices } = await supabase.rpc(
      "get_emergency_services",
      {
        p_state_code: userLocation?.state_code || "LAG",
      }
    );

    // Step 5: Use Groq AI for enhanced analysis
    console.log("🤖 Getting AI-enhanced analysis...");
    const aiAnalysis = await getEnhancedAIAnalysis({
      symptoms,
      locationPredictions,
      userLocation,
      additional_context,
      emergencyServices,
      age_group,
      gender,
    });

    // Step 6: Generate prediction ID
    const prediction_id = `pred_${Date.now()}_${Math.floor(Math.random() * 10000)}`;

    // Step 7: Prepare enhanced result
    const result: EnhancedPredictionResult = {
      illness: locationPredictions?.[0]?.name || "Unknown",
      confidence: locationPredictions?.[0]?.confidence || 0.5,
      urgency: locationPredictions?.[0]?.urgency || "moderate",
      severity: locationPredictions?.[0]?.severity || "moderate",
      matched_symptoms: symptoms,
      advice: aiAnalysis.advice,
      alternative_diagnoses: locationPredictions?.slice(1, 4).map((p: any) => ({
        illness: p.name,
        confidence: p.confidence,
      })) || [],
      location_risk_factors: {
        state_risk: locationPredictions?.[0]?.location_risk_factor || 1.0,
        regional_prevalence: locationPredictions?.[0]?.regional_prevalence || "unknown",
        seasonal_factors: aiAnalysis.seasonal_factors,
      },
      emergency_assessment: {
        is_critical: false,
        emergency_protocols: aiAnalysis.emergency_protocols,
        emergency_contacts: emergencyServices,
      },
      prevention_tips: aiAnalysis.prevention_tips,
      follow_up_advice: aiAnalysis.follow_up_advice,
    };

    // Step 8: Save enhanced prediction to database
    console.log("💾 Saving enhanced prediction to database...");
    const { data: predictionData, error: predError } = await supabase
      .from("predictions")
      .insert({
        user_id,
        symptoms,
        prediction_id: prediction_id,
        prediction_data: result,
        confidence_score: result.confidence,
        urgency: result.urgency as any,
        severity: result.severity as any,
        matched_symptoms: result.matched_symptoms,
        advice: result.advice,
        state_code: userLocation?.state_code,
        lga_code: userLocation?.lga_code,
        location_context: {
          coordinates: userLocation?.coordinates,
          additional_context,
        },
      })
      .select()
      .single();

    if (predError) {
      console.error("❌ Error saving prediction:", predError);
      throw new Error(`Database error: ${predError.message}`);
    }

    // Step 9: Log to Hedera blockchain
    console.log("🔗 Logging to Hedera blockchain...");
    try {
      const hederaResponse = await fetch(
        `${SUPABASE_URL}/functions/v1/log-to-hedera`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
          },
          body: JSON.stringify({
            prediction_id: prediction_id,
            user_id,
            prediction_data: {
              illness: result.illness,
              confidence: result.confidence,
              urgency: result.urgency,
              severity: result.severity,
            },
          }),
        }
      );

      if (hederaResponse.ok) {
        const hederaData = await hederaResponse.json();
        result.hedera_transaction_id = hederaData.hedera_transaction_id;
      }
    } catch (hederaError) {
      console.error("❌ Hedera logging error:", hederaError);
      // Continue without Hedera logging
    }

    console.log("✅ Enhanced prediction completed successfully");

    return new Response(
      JSON.stringify({
        success: true,
        prediction_id: prediction_id,
        result,
        message: "Enhanced prediction completed successfully",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("❌ Error in enhanced prediction:", error);
    return new Response(
      JSON.stringify({
        error: error.message || "Failed to process prediction",
        details: error.toString(),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

// =====================================================
// ENHANCED AI ANALYSIS FUNCTION
// =====================================================
async function getEnhancedAIAnalysis({
  symptoms,
  locationPredictions,
  userLocation,
  additional_context,
  emergencyServices,
  age_group,
  gender,
}: any) {
  try {
    const systemPrompt = `You are Taimako, an advanced AI health assistant specialized in Nigerian medical conditions.

You have access to:
- Location-based health data (${userLocation?.state_code || 'Nigeria'})
- Regional disease patterns
- Emergency services information
- User's additional context
- 50+ medical conditions database

Provide comprehensive health analysis in Nigerian context with cultural sensitivity.`;

    const userPrompt = `Analyze these symptoms: ${symptoms.join(", ")}

Location: ${userLocation?.state_code || "Unknown"}
Age Group: ${age_group || "Not specified"}
Gender: ${gender || "Not specified"}
Additional Context: ${JSON.stringify(additional_context || {})}

Based on the location predictions: ${JSON.stringify(locationPredictions || [])}

Provide detailed analysis in this EXACT JSON format:
{
  "advice": "Detailed medical advice (2-3 sentences in simple English or Pidgin)",
  "prevention_tips": ["tip1", "tip2", "tip3", "tip4"],
  "follow_up_advice": ["advice1", "advice2", "advice3"],
  "emergency_protocols": ["protocol1", "protocol2"],
  "seasonal_factors": ["factor1", "factor2"]
}

Consider:
1. Nigerian medical context and cultural factors
2. Location-specific disease patterns
3. Seasonal factors (rainy season, harmattan, etc.)
4. Emergency protocols if needed
5. Prevention strategies
6. Follow-up care recommendations

Use Nigerian context and be culturally sensitive.`;

    const response = await fetch(GROQ_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        temperature: 0.7,
        max_tokens: 1000,
        response_format: { type: "json_object" },
      }),
    });

    if (!response.ok) {
      throw new Error(`Groq API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    const aiResponse = JSON.parse(data.choices[0].message.content);

    console.log("🤖 Enhanced AI Analysis:", aiResponse);

    return {
      advice: aiResponse.advice || "Please consult a healthcare professional for proper diagnosis and treatment.",
      prevention_tips: aiResponse.prevention_tips || [
        "Maintain good hygiene",
        "Stay hydrated",
        "Avoid risk factors",
        "Seek medical attention if symptoms worsen",
      ],
      follow_up_advice: aiResponse.follow_up_advice || [
        "Monitor symptoms closely",
        "Follow medical advice",
        "Return if symptoms persist",
      ],
      emergency_protocols: aiResponse.emergency_protocols || [],
      seasonal_factors: aiResponse.seasonal_factors || ["Consider current season", "Be aware of seasonal diseases"],
    };
  } catch (error) {
    console.error("❌ AI analysis error:", error);
    return {
      advice: "Please consult a healthcare professional for proper diagnosis and treatment.",
      prevention_tips: ["Maintain good hygiene", "Stay hydrated", "Avoid risk factors"],
      follow_up_advice: ["Monitor symptoms", "Seek medical attention if needed"],
      emergency_protocols: [],
      seasonal_factors: [],
    };
  }
}
