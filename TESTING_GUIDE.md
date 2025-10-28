# 🧪 TAIMAKO TESTING GUIDE

This guide helps you test all components of your Taimako AI Health Assistant before deploying to production.

## 🚀 Quick Start

### Windows (PowerShell)
```powershell
# Run all tests
.\run-all-tests.ps1

# Quick test only
.\run-all-tests.ps1 -QuickOnly

# Skip Hedera tests
.\run-all-tests.ps1 -SkipHedera
```

### Linux/Mac (Bash)
```bash
# Make executable and run
chmod +x run-all-tests.sh
./run-all-tests.sh
```

## 📋 Individual Test Scripts

### 1. Hedera Blockchain Test
```bash
# Test Hedera HCS topic creation
node create-topic.js
```
**Expected Output:**
```
🔗 Creating Hedera HCS Topic...
✅ Topic created successfully!
📝 Topic ID: 0.0.7098028
🔗 Explorer: https://hashscan.io/testnet/topic/0.0.7098028
```

### 2. Edge Functions Test (Comprehensive)
```bash
# Test all Edge Functions with detailed analysis
node test-edge-functions.js
```
**Tests:**
- ✅ predict-illness function
- ✅ log-to-hedera function  
- ✅ get-health-stats function
- ✅ Edge cases and error handling
- ✅ Performance testing

### 3. Edge Functions Test (Quick)
```bash
# Quick test of core functionality
node quick-test.js
```
**Tests:**
- ✅ Basic prediction
- ✅ Health stats
- ✅ AI conversation

### 4. Flutter Integration Test
```bash
# Test Flutter app connectivity
dart test-flutter-integration.dart
```
**Tests:**
- ✅ HTTP requests to Edge Functions
- ✅ JSON parsing
- ✅ Error handling

## 🔧 Prerequisites

### Required Software
- ✅ **Node.js** (v16+)
- ✅ **Dart** (for Flutter integration test)
- ✅ **npm** (for dependencies)

### Required Files
- ✅ `package.json`
- ✅ `create-topic.js`
- ✅ `test-edge-functions.js`
- ✅ `quick-test.js`
- ✅ `test-flutter-integration.dart`

### Environment Setup
1. **Install dependencies:**
   ```bash
   npm install @hashgraph/sdk
   ```

2. **Configure environment:**
   ```bash
   # Copy template
   cp env.example .env
   
   # Edit .env with your actual values
   HEDERA_TOPIC_ID=0.0.7098028
   GROQ_API_KEY=your_groq_api_key_here
   ```

## 📊 Test Results Interpretation

### Success Rates
- **90%+**: 🎉 **EXCELLENT** - Ready for production
- **70-89%**: ⚠️ **GOOD** - Minor issues, mostly working
- **<70%**: ❌ **NEEDS WORK** - Multiple issues detected

### Common Issues & Solutions

#### 1. Hedera Connection Issues
```
❌ Error: Cannot find module '@hashgraph/sdk'
```
**Solution:**
```bash
npm install @hashgraph/sdk
```

#### 2. Edge Function Errors
```
❌ HTTP Error: 500
```
**Solutions:**
- Check Supabase secrets are configured
- Verify Edge Functions are deployed
- Check function logs in Supabase dashboard

#### 3. Missing Environment Variables
```
❌ Missing Hedera configuration
```
**Solution:**
- Add secrets to Supabase Edge Functions
- Update `.env` file with correct values

#### 4. Flutter Integration Issues
```
❌ Exception: Connection refused
```
**Solutions:**
- Check Supabase URL is correct
- Verify Edge Functions are accessible
- Test with curl/Postman first

## 🎯 What Each Test Validates

### Hedera Integration
- ✅ Topic creation works
- ✅ Blockchain connection established
- ✅ Transaction IDs generated

### Edge Functions
- ✅ AI prediction accuracy
- ✅ Database storage
- ✅ Hedera logging
- ✅ Error handling
- ✅ Performance

### Flutter Integration
- ✅ HTTP connectivity
- ✅ JSON parsing
- ✅ Error handling
- ✅ User experience flow

## 🔍 Manual Testing

### Test Prediction Flow
1. **Send symptoms:**
   ```bash
   curl -X POST https://pcqfdxgajkojuffiiykt.supabase.co/functions/v1/predict-illness \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "test-user",
       "symptoms": ["fever", "chills", "headache"],
       "age_group": "adult_20_64"
     }'
   ```

2. **Check response:**
   - Status: 200
   - Success: true
   - Predictions array populated
   - Hedera transaction ID present

### Test Health Stats
```bash
curl -X POST https://pcqfdxgajkojuffiiykt.supabase.co/functions/v1/get-health-stats \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user",
    "stat_type": "summary"
  }'
```

### Test AI Conversation
```bash
curl -X POST https://pcqfdxgajkojuffiiykt.supabase.co/functions/v1/get-health-stats \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user",
    "stat_type": "conversation",
    "query": "What should I do about my fever?"
  }'
```

## 🚨 Troubleshooting

### Edge Function Not Responding
1. Check Supabase dashboard
2. Verify function deployment
3. Check function logs
4. Test with Postman/curl

### Hedera Connection Failed
1. Verify account credentials
2. Check network connectivity
3. Ensure topic exists
4. Verify HBAR balance

### AI Predictions Inaccurate
1. Check medical dataset loaded
2. Verify symptom matching logic
3. Test with known conditions
4. Review confidence thresholds

## 📈 Performance Benchmarks

### Expected Response Times
- **predict-illness**: < 3 seconds
- **get-health-stats**: < 2 seconds
- **log-to-hedera**: < 5 seconds

### Success Criteria
- **Prediction accuracy**: > 80%
- **Uptime**: > 99%
- **Error rate**: < 5%

## 🎉 Ready for Production?

Your Taimako setup is ready when:

- ✅ All tests pass (90%+ success rate)
- ✅ Hedera transactions confirmed
- ✅ AI predictions accurate
- ✅ Edge Functions responding
- ✅ Flutter app connects successfully
- ✅ Error handling works
- ✅ Performance meets benchmarks

## 📞 Support

If tests fail:
1. Check this guide's troubleshooting section
2. Review Supabase function logs
3. Verify environment configuration
4. Test individual components
5. Check Hedera network status

---

**Happy Testing! 🧪✨**
