# Taimako Deployment Guide

## Pre-Deployment Checklist

### 1. Database Setup
Execute these SQL scripts in your Supabase SQL Editor in order:

```bash
1. conversational_chat_schema.sql
2. add_feedback_to_messages.sql
3. fix_get_conversation_function.sql
4. nigerian_location_system.sql (if not already done)
```

### 2. Edge Functions Deployment

Deploy all Edge Functions to Supabase:

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref your-project-ref

# Deploy Edge Functions
supabase functions deploy conversational_ai_edge_function
supabase functions deploy log-to-hedera
supabase functions deploy predict-illness-upgraded
```

### 3. Environment Variables

Set these environment variables in Supabase Dashboard:

```env
# Required for all functions
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# For conversational_ai_edge_function
GROQ_API_KEY=your-groq-api-key

# For log-to-hedera
HEDERA_ACCOUNT_ID=your-hedera-account-id
HEDERA_PRIVATE_KEY=your-hedera-private-key
HEDERA_TOPIC_ID=your-topic-id
HEDERA_NETWORK=testnet

# For predict-illness-upgraded
# Uses SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY
```

### 4. Hedera Testnet Setup

1. Create a Hedera account at [portal.hedera.com](https://portal.hedera.com)
2. Create an HCS topic for logging predictions
3. Note your account ID, private key, and topic ID

### 5. Android APK Build

Build release APK:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

### 6. Testing

Test the following features:
- [ ] User registration and login
- [ ] Profile creation with location data
- [ ] Sending chat messages
- [ ] AI predictions with confidence scores
- [ ] Hedera blockchain logging
- [ ] Like/dislike feedback
- [ ] Conversation history
- [ ] Pull-to-refresh

## GitHub Repository Setup

### 1. Initialize Git

```bash
git init
git add .
git commit -m "Initial commit: Taimako AI Health Assistant"
```

### 2. Add Remote

```bash
git remote add origin https://github.com/yourusername/taimako.git
git branch -M main
git push -u origin main
```

### 3. GitHub Repository Settings

Create a GitHub repository with these details:

**Repository Name**: taimako

**Description**: 
AI-powered health assistant with blockchain verification for Hedera Africa Hackathon 2025

**Visibility**: Public

**Topics** (add these):
- flutter
- ai
- healthcare
- hedera
- blockchain
- health-assistant
- groq
- supabase
- nigeria
- africa
- hackathon
- llama
- conversational-ai

**Badges** (add to README):
```markdown
![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Hedera](https://img.shields.io/badge/Hedera-3E3538?logo=hedera&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?logo=supabase&logoColor=white)
```

## Verification Steps

### 1. Test APK Installation

```bash
# Install on connected device
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 2. Verify Database

Check Supabase Dashboard:
- Tables created successfully
- RLS policies active
- Functions deployed and working

### 3. Verify Edge Functions

Test each function:
```bash
# Test conversational AI
curl -X POST https://your-project.supabase.co/functions/v1/conversational_ai_edge_function \
  -H "Authorization: Bearer your-anon-key" \
  -d '{"message":"I have a headache", "user_id":"test"}'

# Test Hedera logging
# (Verify transactions appear on Hashscan)
```

## Post-Deployment

1. **Monitor Logs**: Check Supabase Edge Function logs for errors
2. **Track Transactions**: Verify Hedera transactions on Hashscan
3. **User Feedback**: Collect feedback through in-app like/dislike
4. **Analytics**: Monitor app usage in Supabase dashboard

## Troubleshooting

### Common Issues

**Issue**: "AuthException: Invalid login credentials"
- **Solution**: Check Supabase Auth settings and confirm email verification

**Issue**: "Edge Function failed with status: 500"
- **Solution**: Check function logs in Supabase Dashboard and verify environment variables

**Issue**: "Hedera transaction failed"
- **Solution**: Verify Hedera credentials and topic ID in Edge Function environment variables

**Issue**: "Database connection error"
- **Solution**: Check Supabase project status and RLS policies

## Security Notes

⚠️ **Never commit**:
- `.env` files
- Private keys
- Service role keys
- Hedera private keys
- API keys

✅ **Safe to commit**:
- `.env.example` (with placeholder values)
- Public configuration
- Database schemas
- Edge Function code

## Support

For deployment issues:
- Check Supabase documentation
- Review Flutter build errors
- Verify Hedera testnet status
- Contact team members

