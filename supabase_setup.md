# Taimako Supabase Setup Guide

This guide will help you set up Supabase for the Taimako AI Health Assistant app.

## 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in to your account
3. Click "New Project"
4. Choose your organization
5. Enter project details:
   - **Name**: `taimako-health`
   - **Database Password**: Generate a strong password
   - **Region**: Choose the closest region to your users
6. Click "Create new project"
7. Wait for the project to be created (2-3 minutes)

## 2. Get Project Credentials

1. Go to **Settings** → **API**
2. Copy the following values:
   - **Project URL** (e.g., `https://your-project.supabase.co`)
   - **Project API Key** (anon/public key)

## 3. Update Flutter App Configuration

Update the following files in your Flutter app:

### `lib/main.dart`
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL', // Replace with your actual Supabase URL
  anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your actual Supabase anon key
);
```

### `lib/services/supabase_service.dart`
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

## 4. Database Setup

Run the following SQL commands in your Supabase SQL Editor:

### Create Tables

```sql
-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Users table (extends Supabase auth.users)
CREATE TABLE user_profiles (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  profile_data JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Predictions table
CREATE TABLE predictions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  symptoms TEXT[] NOT NULL,
  prediction_id TEXT NOT NULL,
  prediction_data JSONB NOT NULL,
  hedera_transaction_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Hedera logs table
CREATE TABLE hedera_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  prediction_id TEXT NOT NULL,
  hedera_transaction_id TEXT NOT NULL,
  log_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Health articles table
CREATE TABLE health_articles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  author TEXT DEFAULT 'Taimako Team',
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_predictions_user_id ON predictions(user_id);
CREATE INDEX idx_predictions_created_at ON predictions(created_at);
CREATE INDEX idx_hedera_logs_user_id ON hedera_logs(user_id);
CREATE INDEX idx_hedera_logs_transaction_id ON hedera_logs(hedera_transaction_id);
CREATE INDEX idx_health_articles_category ON health_articles(category);
CREATE INDEX idx_health_articles_published ON health_articles(is_published);
```

### Set up Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE hedera_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_articles ENABLE ROW LEVEL SECURITY;

-- User profiles policies
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Predictions policies
CREATE POLICY "Users can view own predictions" ON predictions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own predictions" ON predictions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Hedera logs policies
CREATE POLICY "Users can view own hedera logs" ON hedera_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own hedera logs" ON hedera_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Health articles policies (public read)
CREATE POLICY "Anyone can view published articles" ON health_articles
  FOR SELECT USING (is_published = true);
```

### Insert Sample Health Articles

```sql
-- Insert sample health articles
INSERT INTO health_articles (title, content, category, is_published) VALUES
('Understanding Malaria in Nigeria', 'Malaria is one of the most common diseases in Nigeria...', 'Malaria', true),
('Preventing Typhoid Fever', 'Typhoid fever is a bacterial infection that can be prevented...', 'Typhoid', true),
('Managing Hypertension', 'High blood pressure affects many Nigerians. Here''s how to manage it...', 'Hypertension', true),
('Common Cold Prevention', 'Simple steps to prevent and manage common colds...', 'General Health', true),
('When to Seek Medical Help', 'Know when your symptoms require immediate medical attention...', 'Emergency', true);
```

## 5. Edge Functions Setup

### Create the Prediction Edge Function

1. Go to **Edge Functions** in your Supabase dashboard
2. Click "Create a new function"
3. Name it `predict-illness`
4. Use the following code:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { symptoms, age_group, gender, season, location } = await req.json()

    // Simple AI prediction logic (replace with your actual AI model)
    const predictions = await predictIllness(symptoms, { age_group, gender, season, location })

    return new Response(
      JSON.stringify({ 
        success: true, 
        predictions,
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})

// Simple prediction function (replace with your actual AI model)
async function predictIllness(symptoms: string[], context: any) {
  // This is a simplified example - replace with your actual AI model
  const commonConditions = [
    { name: 'Malaria', confidence: 0.85, symptoms: ['fever', 'chills', 'headache'] },
    { name: 'Typhoid', confidence: 0.75, symptoms: ['fever', 'abdominal_pain', 'headache'] },
    { name: 'Common Cold', confidence: 0.90, symptoms: ['runny_nose', 'sneezing', 'sore_throat'] },
  ]

  const matchedConditions = commonConditions
    .map(condition => {
      const matchedSymptoms = condition.symptoms.filter(s => 
        symptoms.some(userSymptom => 
          userSymptom.toLowerCase().includes(s.toLowerCase())
        )
      )
      return {
        ...condition,
        confidence: (matchedSymptoms.length / condition.symptoms.length) * condition.confidence,
        matched_symptoms: matchedSymptoms
      }
    })
    .filter(condition => condition.confidence > 0.3)
    .sort((a, b) => b.confidence - a.confidence)

  return matchedConditions.slice(0, 3) // Return top 3 predictions
}
```

### Create the Hedera Logging Edge Function

1. Create another Edge Function named `log-to-hedera`
2. Use the following code:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { user_id, prediction_id, prediction_data } = await req.json()

    // Simulate Hedera HCS logging (replace with actual Hedera integration)
    const hederaTransactionId = await logToHederaHCS({
      user_id,
      prediction_id,
      prediction_data
    })

    return new Response(
      JSON.stringify({ 
        success: true, 
        hedera_transaction_id: hederaTransactionId,
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})

// Simulate Hedera HCS logging
async function logToHederaHCS(data: any) {
  // In production, this would use the Hedera SDK
  // For now, we'll simulate a transaction ID
  const timestamp = Date.now()
  const randomId = Math.floor(Math.random() * 1000000)
  return `0.0.123456@${timestamp}.${randomId}`
}
```

## 6. Authentication Setup

1. Go to **Authentication** → **Settings**
2. Configure the following:
   - **Site URL**: `http://localhost:3000` (for development)
   - **Redirect URLs**: Add your app's redirect URLs
   - **Email Templates**: Customize if needed

## 7. Test Your Setup

1. Run your Flutter app
2. Try to sign up with a test email
3. Check the **Authentication** → **Users** section in Supabase
4. Try making a prediction and check the **Table Editor** for data

## 8. Production Considerations

- Update your Supabase URL and keys for production
- Set up proper CORS policies
- Configure email templates
- Set up monitoring and alerts
- Consider using Supabase's built-in analytics

## Troubleshooting

### Common Issues

1. **CORS errors**: Make sure your Edge Functions have proper CORS headers
2. **RLS errors**: Check that your Row Level Security policies are correct
3. **Authentication errors**: Verify your Supabase URL and keys are correct
4. **Edge Function errors**: Check the function logs in the Supabase dashboard

### Getting Help

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Discord](https://discord.supabase.com)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
