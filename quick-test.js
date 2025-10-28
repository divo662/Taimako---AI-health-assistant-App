#!/usr/bin/env node
/**
 * =====================================================
 * TAIMAKO - QUICK EDGE FUNCTION TEST
 * =====================================================
 * 
 * Quick test to verify Edge Functions are working
 * Run: node quick-test.js
 */

const https = require('https');

// Configuration
const SUPABASE_URL = 'https://pcqfdxgajkojuffiiykt.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjcWZkeGdhamtvanVmZmlpeWt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4NzYyMzYsImV4cCI6MjA3NjQ1MjIzNn0.lf0e9v-qyOXPa_GQPsBRbyMH_VfcNJS2oash49RD_ik';
const TEST_USER_ID = 'ce0dfef5-fdbc-40ce-9d11-4045aec499b3'; // Real authenticated user

// Utility function
function makeRequest(url, data) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    
    const options = {
      hostname: urlObj.hostname,
      port: 443,
      path: urlObj.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'apikey': SUPABASE_ANON_KEY,
        'Content-Length': Buffer.byteLength(JSON.stringify(data))
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = JSON.parse(responseData);
          resolve({
            status: res.statusCode,
            data: parsed
          });
        } catch (e) {
          resolve({
            status: res.statusCode,
            data: responseData
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(JSON.stringify(data));
    req.end();
  });
}

async function quickTest() {
  console.log('🚀 TAIMAKO QUICK TEST');
  console.log('=====================');
  console.log(`👤 Test User: ${TEST_USER_ID}`);
  console.log(`🌐 Supabase: ${SUPABASE_URL}\n`);

  try {
    // Test 1: Predict Illness
    console.log('🔍 Testing predict-illness...');
    
    const predictionData = {
      user_id: TEST_USER_ID,
      symptoms: ['fever', 'chills', 'headache', 'body_aches'],
      age_group: 'adult_20_64',
      gender: 'male',
      season: 'rainy_season',
      location: 'Lagos, Nigeria'
    };

    const predictionResponse = await makeRequest(
      SUPABASE_URL + '/functions/v1/predict-illness',
      predictionData
    );

    console.log(`   Status: ${predictionResponse.status}`);
    
    if (predictionResponse.status === 200 && predictionResponse.data.success) {
      console.log(`   ✅ Success! Response received`);
      console.log(`   📊 Response data:`, JSON.stringify(predictionResponse.data, null, 2));
      
      if (predictionResponse.data.predictions && predictionResponse.data.predictions.length > 0) {
        const prediction = predictionResponse.data.predictions[0];
        console.log(`   🎯 Predicted: ${prediction.conditionName}`);
        console.log(`   📊 Confidence: ${prediction.confidencePercentage}`);
        console.log(`   ⚠️  Urgency: ${prediction.urgencyLevel}`);
      }
      
      if (predictionResponse.data.hedera_transaction_id) {
        console.log(`   🔗 Hedera TX: ${predictionResponse.data.hedera_transaction_id}`);
      }
      
      // Test 2: Health Stats
      console.log('\n📊 Testing get-health-stats...');
      
      const statsData = {
        user_id: TEST_USER_ID,
        stat_type: 'summary',
        time_period: '30days'
      };

      const statsResponse = await makeRequest(
        SUPABASE_URL + '/functions/v1/get-health-stats',
        statsData
      );

      console.log(`   Status: ${statsResponse.status}`);
      
      if (statsResponse.status === 200 && statsResponse.data.success) {
        console.log(`   ✅ Success! Total predictions: ${statsResponse.data.data.total_predictions}`);
        console.log(`   🎯 Most common illness: ${statsResponse.data.data.most_common_illness}`);
      } else {
        console.log(`   ❌ Stats failed: ${JSON.stringify(statsResponse.data)}`);
      }
      
      // Test 3: AI Conversation
      console.log('\n🤖 Testing AI conversation...');
      
      const conversationData = {
        user_id: TEST_USER_ID,
        stat_type: 'conversation',
        query: 'What should I do about my fever?'
      };

      const conversationResponse = await makeRequest(
        SUPABASE_URL + '/functions/v1/get-health-stats',
        conversationData
      );

      console.log(`   Status: ${conversationResponse.status}`);
      
      if (conversationResponse.status === 200 && conversationResponse.data.success) {
        console.log(`   ✅ AI Response: ${conversationResponse.data.data.response.substring(0, 100)}...`);
      } else {
        console.log(`   ❌ AI conversation failed: ${JSON.stringify(conversationResponse.data)}`);
      }
      
    } else {
      console.log(`   ❌ Prediction failed: ${JSON.stringify(predictionResponse.data)}`);
    }

  } catch (error) {
    console.error('❌ Test error:', error.message);
  }

  console.log('\n🏁 Quick test completed!');
}

// Run the test
quickTest().catch(console.error);
