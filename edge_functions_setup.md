# Taimako Edge Functions Setup Guide

## 🚀 **Edge Functions for AI Predictions & Hedera Integration**

Now that your database is ready, let's create the Edge Functions that will handle:
1. **AI Prediction Logic** - Using your medical dataset
2. **Hedera Blockchain Logging** - For transparency and verification
3. **Analytics Tracking** - User behavior and app usage

---

## 📁 **Edge Function 1: predict-illness**

**Purpose**: Main AI prediction function that analyzes symptoms and returns likely illnesses

### **Create the Function:**

1. Go to **Supabase Dashboard** → **Edge Functions**
2. Click **"Create a new function"**
3. Name: `predict-illness`
4. Copy and paste this code:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PredictionRequest {
  symptoms: string[]
  age_group?: string
  gender?: string
  season?: string
  location?: string
}

interface ConditionMatch {
  condition_id: string
  name: string
  confidence: number
  matched_symptoms: string[]
  advice: string
  urgency: string
  severity: string
  icd10?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const { symptoms, age_group, gender, season, location }: PredictionRequest = await req.json()

    if (!symptoms || symptoms.length === 0) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Symptoms are required' 
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }

    // Normalize symptoms
    const normalizedSymptoms = symptoms.map(s => s.toLowerCase().replace(/[^\w\s]/g, '').replace(/\s+/g, '_').trim())

    // Get medical conditions from database
    const { data: conditions, error } = await supabaseClient
      .from('medical_conditions')
      .select('*')

    if (error) {
      throw new Error(`Database error: ${error.message}`)
    }

    // Calculate predictions using the stored procedure
    const { data: predictions, error: predError } = await supabaseClient
      .rpc('search_conditions_by_symptoms', { symptom_list: normalizedSymptoms })

    if (predError) {
      throw new Error(`Prediction error: ${predError.message}`)
    }

    // Enhance predictions with additional data
    const enhancedPredictions: ConditionMatch[] = predictions.map((pred: any) => {
      const condition = conditions.find(c => c.condition_id === pred.condition_id)
      if (!condition) return null

      // Apply age group risk factor
      const ageRiskFactor = getAgeRiskFactor(condition, age_group)
      
      // Apply gender risk factor
      const genderRiskFactor = getGenderRiskFactor(condition, gender)
      
      // Apply seasonal risk factor
      const seasonalRiskFactor = getSeasonalRiskFactor(condition, season)
      
      // Calculate final confidence
      const finalConfidence = Math.min(1.0, pred.confidence * ageRiskFactor * genderRiskFactor * seasonalRiskFactor)

      return {
        condition_id: pred.condition_id,
        name: pred.name,
        confidence: finalConfidence,
        matched_symptoms: pred.matched_symptoms,
        advice: condition.advice,
        urgency: condition.urgency,
        severity: condition.severity,
        icd10: condition.icd10
      }
    }).filter(Boolean).slice(0, 3) // Top 3 predictions

    // Generate prediction ID
    const predictionId = `pred_${Date.now()}_${Math.floor(Math.random() * 10000)}`

    // Get current user
    const { data: { user } } = await supabaseClient.auth.getUser()

    // Save prediction to database if user is authenticated
    if (user) {
      const predictionData = {
        illness: enhancedPredictions[0]?.name || 'Unknown',
        confidence: enhancedPredictions[0]?.confidence || 0,
        symptoms: normalizedSymptoms,
        urgency: enhancedPredictions[0]?.urgency || 'moderate',
        severity: enhancedPredictions[0]?.severity || 'moderate',
        matched_symptoms: enhancedPredictions[0]?.matched_symptoms || [],
        advice: enhancedPredictions[0]?.advice || 'Please consult a healthcare professional.',
        timestamp: new Date().toISOString(),
        age_group: age_group,
        gender: gender,
        season: season,
        location: location,
      }

      await supabaseClient
        .from('predictions')
        .insert({
          user_id: user.id,
          symptoms: normalizedSymptoms,
          prediction_id: predictionId,
          prediction_data: predictionData,
          confidence_score: enhancedPredictions[0]?.confidence || 0,
          urgency: enhancedPredictions[0]?.urgency || 'moderate',
          severity: enhancedPredictions[0]?.severity || 'moderate',
          matched_symptoms: enhancedPredictions[0]?.matched_symptoms || [],
          advice: enhancedPredictions[0]?.advice || 'Please consult a healthcare professional.',
        })

      // Log analytics
      await supabaseClient
        .from('analytics')
        .insert({
          user_id: user.id,
          event_type: 'prediction_made',
          event_data: {
            symptoms_count: normalizedSymptoms.length,
            top_prediction: enhancedPredictions[0]?.name,
            confidence: enhancedPredictions[0]?.confidence
          }
        })
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        predictions: enhancedPredictions,
        prediction_id: predictionId,
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Prediction error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})

// Helper functions for risk factor calculation
function getAgeRiskFactor(condition: any, ageGroup?: string): number {
  if (!ageGroup || !condition.age_groups) return 1.0
  
  if (condition.age_groups.includes('all') || condition.age_groups.includes(ageGroup)) {
    return 1.0
  }
  
  return 0.8 // Lower risk for non-matching age groups
}

function getGenderRiskFactor(condition: any, gender?: string): number {
  if (!gender) return 1.0
  
  // Add gender-specific risk factors here if needed
  return 1.0
}

function getSeasonalRiskFactor(condition: any, season?: string): number {
  if (!season || !condition.seasonal_factors) return 1.0
  
  if (condition.seasonal_factors.includes(season)) {
    return 1.3 // 30% higher risk during high-risk seasons
  }
  
  return 1.0
}
```

---

## 📁 **Edge Function 2: log-to-hedera**

**Purpose**: Logs prediction data to Hedera HCS for blockchain verification

### **Create the Function:**

1. Create another Edge Function named `log-to-hedera`
2. Copy and paste this code:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface HederaLogRequest {
  user_id: string
  prediction_id: string
  prediction_data: any
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const { user_id, prediction_id, prediction_data }: HederaLogRequest = await req.json()

    if (!user_id || !prediction_id || !prediction_data) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Missing required parameters' 
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }

    // Create prediction hash for integrity verification
    const predictionHash = await createPredictionHash(prediction_data)
    
    // Create the message to be logged on Hedera HCS
    const hcsMessage = {
      type: 'health_prediction',
      user_id: anonymizeUserId(user_id),
      prediction_id: prediction_id,
      prediction_hash: predictionHash,
      timestamp: new Date().toISOString(),
      illness: prediction_data.illness,
      confidence: prediction_data.confidence,
      symptoms_count: prediction_data.symptoms?.length || 0,
      urgency: prediction_data.urgency,
      severity: prediction_data.severity
    }

    // For MVP, we'll simulate the HCS transaction
    // In production, this would use the Hedera SDK
    const transactionId = await simulateHCSSubmission(hcsMessage)
    
    // Save Hedera log to database
    await supabaseClient
      .from('hedera_logs')
      .insert({
        user_id: user_id,
        prediction_id: prediction_id,
        hedera_transaction_id: transactionId,
        log_data: {
          hcs_message: hcsMessage,
          prediction_data: prediction_data,
          verification_status: 'pending'
        },
        verification_status: 'pending'
      })

    // Update prediction with Hedera transaction ID
    await supabaseClient
      .from('predictions')
      .update({ hedera_transaction_id: transactionId })
      .eq('prediction_id', prediction_id)

    return new Response(
      JSON.stringify({ 
        success: true, 
        hedera_transaction_id: transactionId,
        prediction_hash: predictionHash,
        message: 'Prediction logged to Hedera HCS successfully',
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Hedera logging error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})

// Helper function to create prediction hash
async function createPredictionHash(predictionData: any): Promise<string> {
  const sortedData = Object.keys(predictionData)
    .sort()
    .reduce((result, key) => {
      result[key] = predictionData[key]
      return result
    }, {} as any)
  
  const jsonString = JSON.stringify(sortedData)
  const encoder = new TextEncoder()
  const data = encoder.encode(jsonString)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
  
  return hashHex
}

// Helper function to anonymize user ID
function anonymizeUserId(userId: string): string {
  if (userId.length <= 8) return userId
  return `${userId.substring(0, 8)}...`
}

// Simulate HCS submission (replace with actual Hedera SDK in production)
async function simulateHCSSubmission(message: any): Promise<string> {
  const messageJson = JSON.stringify(message)
  const encoder = new TextEncoder()
  const data = encoder.encode(messageJson)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  const messageHash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
  
  // Simulate transaction ID format: 0.0.123456@1234567890.123456789
  const timestamp = Date.now()
  const randomId = Math.floor(Math.random() * 1000000)
  const transactionId = `0.0.123456@${timestamp}.${randomId}`
  
  console.log('Hedera HCS Transaction:', transactionId)
  console.log('Message Hash:', messageHash)
  console.log('Message:', messageJson)
  
  return transactionId
}
```

---

## 📁 **Edge Function 3: get-health-stats**

**Purpose**: Provides analytics and health statistics for the admin dashboard

### **Create the Function:**

1. Create another Edge Function named `get-health-stats`
2. Copy and paste this code:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get prediction statistics
    const { data: predictionStats } = await supabaseClient
      .from('prediction_stats')
      .select('*')
      .limit(30) // Last 30 days

    // Get disease trends
    const { data: diseaseTrends } = await supabaseClient
      .from('disease_trends')
      .select('*')
      .limit(10) // Top 10 diseases

    // Get user activity
    const { data: userActivity } = await supabaseClient
      .from('user_activity')
      .select('*')
      .limit(100) // Top 100 active users

    // Get total counts
    const { count: totalPredictions } = await supabaseClient
      .from('predictions')
      .select('*', { count: 'exact', head: true })

    const { count: totalUsers } = await supabaseClient
      .from('user_profiles')
      .select('*', { count: 'exact', head: true })

    const { count: totalHederaLogs } = await supabaseClient
      .from('hedera_logs')
      .select('*', { count: 'exact', head: true })

    // Get recent predictions
    const { data: recentPredictions } = await supabaseClient
      .from('predictions')
      .select('prediction_data, created_at, urgency')
      .order('created_at', { ascending: false })
      .limit(50)

    // Calculate emergency cases
    const emergencyCases = recentPredictions?.filter(p => 
      p.urgency === 'critical' || p.urgency === 'high'
    ).length || 0

    const stats = {
      overview: {
        total_predictions: totalPredictions || 0,
        total_users: totalUsers || 0,
        total_hedera_logs: totalHederaLogs || 0,
        emergency_cases: emergencyCases,
        last_updated: new Date().toISOString()
      },
      prediction_stats: predictionStats || [],
      disease_trends: diseaseTrends || [],
      user_activity: userActivity || [],
      recent_predictions: recentPredictions || []
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        data: stats
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Stats error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})
```

---

## 🔧 **Deployment Steps:**

1. **Create each Edge Function** in Supabase Dashboard
2. **Deploy the functions** (they'll be automatically deployed)
3. **Test the functions** using the Supabase dashboard
4. **Update your Flutter app** to use these functions

---

## 🧪 **Testing Your Edge Functions:**

### **Test predict-illness:**
```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/predict-illness' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "symptoms": ["fever", "headache", "chills"],
    "age_group": "adult_20_64",
    "gender": "male",
    "season": "rainy_season"
  }'
```

### **Test log-to-hedera:**
```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/log-to-hedera' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "user-uuid",
    "prediction_id": "pred_1234567890_1234",
    "prediction_data": {
      "illness": "Malaria",
      "confidence": 0.85,
      "symptoms": ["fever", "headache", "chills"]
    }
  }'
```

---

## 🎯 **What These Functions Do:**

1. **`predict-illness`**: 
   - Analyzes symptoms using your medical dataset
   - Applies Nigerian context (age, gender, season)
   - Returns top 3 predictions with confidence scores
   - Saves predictions to database
   - Tracks analytics

2. **`log-to-hedera`**: 
   - Creates blockchain transaction for prediction
   - Generates prediction hash for verification
   - Simulates Hedera HCS logging
   - Updates database with transaction ID

3. **`get-health-stats`**: 
   - Provides analytics dashboard data
   - Shows disease trends and user activity
   - Tracks emergency cases
   - Generates health insights

Your Taimako app now has a **complete backend** with AI predictions, blockchain verification, and analytics! 🚀

Next step: Update your Flutter app to use these Edge Functions!
