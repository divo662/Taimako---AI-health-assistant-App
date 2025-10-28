#!/usr/bin/env node
/**
 * =====================================================
 * TAIMAKO - COMPREHENSIVE EDGE FUNCTION TEST SUITE
 * =====================================================
 * 
 * This script tests all Edge Functions:
 * 1. predict-illness (AI + Database + Hedera logging)
 * 2. log-to-hedera (Blockchain verification)
 * 3. get-health-stats (Analytics + AI conversation)
 * 
 * Run: node test-edge-functions.js
 */

const https = require('https');
const fs = require('fs');

// =====================================================
// CONFIGURATION
// =====================================================

const CONFIG = {
  SUPABASE_URL: 'https://pcqfdxgajkojuffiiykt.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjcWZkeGdhamtvanVmZmlpeWt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4NzYyMzYsImV4cCI6MjA3NjQ1MjIzNn0.lf0e9v-qyOXPa_GQPsBRbyMH_VfcNJS2oash49RD_ik',
  FUNCTIONS: {
    PREDICT_ILLNESS: '/functions/v1/predict-illness',
    LOG_HEDERA: '/functions/v1/log-to-hedera', 
    HEALTH_STATS: '/functions/v1/get-health-stats'
  },
  TEST_USER_ID: 'ce0dfef5-fdbc-40ce-9d11-4045aec499b3', // Real authenticated user
  TEST_SYMPTOMS: [
    ['fever', 'chills', 'headache', 'body_aches'],
    ['cough', 'chest_pain', 'shortness_of_breath'],
    ['diarrhea', 'abdominal_cramps', 'nausea'],
    ['fatigue', 'weakness', 'pale_skin'],
    ['severe_headache', 'fever', 'stiff_neck']
  ],
  TEST_CASES: [
    {
      name: 'Malaria Symptoms',
      symptoms: ['fever', 'chills', 'headache', 'body_aches'],
      expected_illness: 'Malaria',
      expected_urgency: 'moderate'
    },
    {
      name: 'Pneumonia Symptoms', 
      symptoms: ['cough', 'chest_pain', 'shortness_of_breath'],
      expected_illness: 'Pneumonia',
      expected_urgency: 'high'
    },
    {
      name: 'Meningitis Symptoms',
      symptoms: ['severe_headache', 'fever', 'stiff_neck'],
      expected_illness: 'Meningitis', 
      expected_urgency: 'critical'
    }
  ]
};

// =====================================================
// TEST RESULTS TRACKING
// =====================================================

const testResults = {
  total: 0,
  passed: 0,
  failed: 0,
  errors: [],
  predictions: [],
  hederaTransactions: []
};

// =====================================================
// UTILITY FUNCTIONS
// =====================================================

function makeRequest(url, data, method = 'POST') {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    
    const options = {
      hostname: urlObj.hostname,
      port: 443,
      path: urlObj.pathname,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${CONFIG.SUPABASE_ANON_KEY}`,
        'apikey': CONFIG.SUPABASE_ANON_KEY,
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
            data: parsed,
            headers: res.headers
          });
        } catch (e) {
          resolve({
            status: res.statusCode,
            data: responseData,
            headers: res.headers
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

function logTest(testName, passed, details = '') {
  testResults.total++;
  if (passed) {
    testResults.passed++;
    console.log(`✅ ${testName}`);
  } else {
    testResults.failed++;
    testResults.errors.push({ test: testName, details });
    console.log(`❌ ${testName}: ${details}`);
  }
}

function logSection(title) {
  console.log('\n' + '='.repeat(60));
  console.log(`🧪 ${title}`);
  console.log('='.repeat(60));
}

// =====================================================
// TEST 1: PREDICT ILLNESS FUNCTION
// =====================================================

async function testPredictIllness() {
  logSection('TESTING PREDICT-ILLNESS FUNCTION');
  
  for (let i = 0; i < CONFIG.TEST_CASES.length; i++) {
    const testCase = CONFIG.TEST_CASES[i];
    console.log(`\n🔍 Testing: ${testCase.name}`);
    
    try {
      const requestData = {
        user_id: CONFIG.TEST_USER_ID,
        symptoms: testCase.symptoms,
        age_group: 'adult_20_64',
        gender: 'male',
        season: 'rainy_season',
        location: 'Lagos, Nigeria'
      };

      const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTIONS.PREDICT_ILLNESS;
      const response = await makeRequest(url, requestData);
      
      // Check response status
      const statusOk = response.status === 200;
      logTest(`${testCase.name} - Status Code`, statusOk, 
        statusOk ? 'OK' : `Expected 200, got ${response.status}`);
      
      if (!statusOk) {
        console.log('Response:', JSON.stringify(response.data, null, 2));
        continue;
      }

      // Check response structure
      const hasSuccess = response.data.success === true;
      logTest(`${testCase.name} - Response Success`, hasSuccess);
      
      const hasPredictions = response.data.predictions && response.data.predictions.length > 0;
      logTest(`${testCase.name} - Has Predictions`, hasPredictions);
      
      if (hasPredictions) {
        const topPrediction = response.data.predictions[0];
        const illnessMatch = topPrediction.conditionName.toLowerCase().includes(testCase.expected_illness.toLowerCase());
        logTest(`${testCase.name} - Illness Match`, illnessMatch, 
          illnessMatch ? `Found: ${topPrediction.conditionName}` : `Expected: ${testCase.expected_illness}, Got: ${topPrediction.conditionName}`);
        
        const urgencyMatch = topPrediction.urgency === testCase.expected_urgency;
        logTest(`${testCase.name} - Urgency Match`, urgencyMatch,
          urgencyMatch ? `Correct urgency: ${topPrediction.urgency}` : `Expected: ${testCase.expected_urgency}, Got: ${topPrediction.urgency}`);
        
        const confidenceOk = topPrediction.confidence > 0.3;
        logTest(`${testCase.name} - Confidence Score`, confidenceOk,
          confidenceOk ? `Confidence: ${topPrediction.confidencePercentage}` : `Low confidence: ${topPrediction.confidencePercentage}`);
        
        // Store prediction for later tests
        testResults.predictions.push({
          prediction_id: response.data.prediction_id,
          user_id: CONFIG.TEST_USER_ID,
          illness: topPrediction.conditionName,
          confidence: topPrediction.confidence,
          urgency: topPrediction.urgency,
          severity: topPrediction.severity
        });
        
        console.log(`📊 Prediction Details:`);
        console.log(`   Illness: ${topPrediction.conditionName}`);
        console.log(`   Confidence: ${topPrediction.confidencePercentage}`);
        console.log(`   Urgency: ${topPrediction.urgencyLevel}`);
        console.log(`   Advice: ${topPrediction.advice.substring(0, 100)}...`);
      }
      
      // Check Hedera integration
      const hasHederaTx = response.data.hedera_transaction_id;
      logTest(`${testCase.name} - Hedera Transaction`, !!hasHederaTx,
        hasHederaTx ? `TX: ${response.data.hedera_transaction_id}` : 'No Hedera transaction ID');
      
      if (hasHederaTx) {
        testResults.hederaTransactions.push(response.data.hedera_transaction_id);
      }
      
    } catch (error) {
      logTest(`${testCase.name} - Request Error`, false, error.message);
    }
  }
}

// =====================================================
// TEST 2: LOG TO HEDERA FUNCTION (Direct Test)
// =====================================================

async function testLogToHedera() {
  logSection('TESTING LOG-TO-HEDERA FUNCTION');
  
  if (testResults.predictions.length === 0) {
    console.log('⚠️  No predictions available to test Hedera logging');
    return;
  }
  
  const testPrediction = testResults.predictions[0];
  
  try {
    const requestData = {
      prediction_id: testPrediction.prediction_id,
      user_id: testPrediction.user_id,
      prediction_data: {
        illness: testPrediction.illness,
        confidence: testPrediction.confidence,
        urgency: testPrediction.urgency,
        severity: testPrediction.severity
      }
    };

    const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTIONS.LOG_HEDERA;
    const response = await makeRequest(url, requestData);
    
    // Check response status
    const statusOk = response.status === 200;
    logTest('Hedera Log - Status Code', statusOk,
      statusOk ? 'OK' : `Expected 200, got ${response.status}`);
    
    if (!statusOk) {
      console.log('Response:', JSON.stringify(response.data, null, 2));
      return;
    }
    
    // Check response structure
    const hasSuccess = response.data.success === true;
    logTest('Hedera Log - Response Success', hasSuccess);
    
    const hasTransactionId = !!response.data.hedera_transaction_id;
    logTest('Hedera Log - Transaction ID', hasTransactionId,
      hasTransactionId ? `TX: ${response.data.hedera_transaction_id}` : 'No transaction ID');
    
    const hasExplorerUrl = !!response.data.explorer_url;
    logTest('Hedera Log - Explorer URL', hasExplorerUrl,
      hasExplorerUrl ? `URL: ${response.data.explorer_url}` : 'No explorer URL');
    
    if (hasTransactionId) {
      console.log(`🔗 Hedera Transaction: ${response.data.hedera_transaction_id}`);
      console.log(`🌐 Explorer: ${response.data.explorer_url}`);
    }
    
  } catch (error) {
    logTest('Hedera Log - Request Error', false, error.message);
  }
}

// =====================================================
// TEST 3: HEALTH STATS FUNCTION
// =====================================================

async function testHealthStats() {
  logSection('TESTING GET-HEALTH-STATS FUNCTION');
  
  const statTypes = ['summary', 'history', 'trends', 'advice', 'conversation'];
  
  for (const statType of statTypes) {
    console.log(`\n📊 Testing: ${statType} stats`);
    
    try {
      const requestData = {
        user_id: CONFIG.TEST_USER_ID,
        stat_type: statType,
        time_period: '30days'
      };
      
      // Add query for conversation test
      if (statType === 'conversation') {
        requestData.query = 'What are my most common health issues?';
      }
      
      const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTIONS.HEALTH_STATS;
      const response = await makeRequest(url, requestData);
      
      // Check response status
      const statusOk = response.status === 200;
      logTest(`${statType} Stats - Status Code`, statusOk,
        statusOk ? 'OK' : `Expected 200, got ${response.status}`);
      
      if (!statusOk) {
        console.log('Response:', JSON.stringify(response.data, null, 2));
        continue;
      }
      
      // Check response structure
      const hasSuccess = response.data.success === true;
      logTest(`${statType} Stats - Response Success`, hasSuccess);
      
      const hasData = !!response.data.data;
      logTest(`${statType} Stats - Has Data`, hasData);
      
      if (hasData) {
        console.log(`📈 ${statType} Stats Data:`);
        console.log(JSON.stringify(response.data.data, null, 2));
      }
      
    } catch (error) {
      logTest(`${statType} Stats - Request Error`, false, error.message);
    }
  }
}

// =====================================================
// TEST 4: EDGE CASE TESTING
// =====================================================

async function testEdgeCases() {
  logSection('TESTING EDGE CASES');
  
  // Test 1: Empty symptoms
  try {
    const requestData = {
      user_id: CONFIG.TEST_USER_ID,
      symptoms: []
    };
    
    const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTIONS.PREDICT_ILLNESS;
    const response = await makeRequest(url, requestData);
    
    const handlesEmpty = response.status === 400 || response.data.error;
    logTest('Empty Symptoms Handling', handlesEmpty,
      handlesEmpty ? 'Properly rejected' : 'Should reject empty symptoms');
    
  } catch (error) {
    logTest('Empty Symptoms - Request Error', false, error.message);
  }
  
  // Test 2: Invalid user ID
  try {
    const requestData = {
      user_id: '',
      symptoms: ['fever']
    };
    
    const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTIONS.PREDICT_ILLNESS;
    const response = await makeRequest(url, requestData);
    
    const handlesInvalid = response.status === 400 || response.data.error;
    logTest('Invalid User ID Handling', handlesInvalid,
      handlesInvalid ? 'Properly rejected' : 'Should reject invalid user ID');
    
  } catch (error) {
    logTest('Invalid User ID - Request Error', false, error.message);
  }
  
  // Test 3: Non-existent user stats
  try {
    const requestData = {
      user_id: 'non-existent-user',
      stat_type: 'summary'
    };
    
    const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTIONS.HEALTH_STATS;
    const response = await makeRequest(url, requestData);
    
    const handlesNonExistent = response.status === 200 && response.data.success;
    logTest('Non-existent User Stats', handlesNonExistent,
      handlesNonExistent ? 'Handled gracefully' : 'Should handle non-existent users');
    
  } catch (error) {
    logTest('Non-existent User Stats - Request Error', false, error.message);
  }
}

// =====================================================
// TEST 5: PERFORMANCE TESTING
// =====================================================

async function testPerformance() {
  logSection('TESTING PERFORMANCE');
  
  const startTime = Date.now();
  
  try {
    // Test multiple rapid requests
    const promises = [];
    for (let i = 0; i < 3; i++) {
      const requestData = {
        user_id: CONFIG.TEST_USER_ID,
        symptoms: ['fever', 'headache'],
        age_group: 'adult_20_64'
      };
      
      const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTIONS.PREDICT_ILLNESS;
      promises.push(makeRequest(url, requestData));
    }
    
    const responses = await Promise.all(promises);
    const endTime = Date.now();
    const totalTime = endTime - startTime;
    
    const allSuccessful = responses.every(r => r.status === 200);
    logTest('Concurrent Requests', allSuccessful,
      allSuccessful ? `All ${responses.length} requests successful` : 'Some requests failed');
    
    const avgTime = totalTime / responses.length;
    const performanceOk = avgTime < 5000; // Less than 5 seconds per request
    logTest('Response Time', performanceOk,
      performanceOk ? `Avg: ${avgTime.toFixed(0)}ms` : `Slow: ${avgTime.toFixed(0)}ms`);
    
  } catch (error) {
    logTest('Performance Test - Request Error', false, error.message);
  }
}

// =====================================================
// MAIN TEST RUNNER
// =====================================================

async function runAllTests() {
  console.log('🚀 TAIMAKO EDGE FUNCTION TEST SUITE');
  console.log('=====================================');
  console.log(`📅 Test started at: ${new Date().toISOString()}`);
  console.log(`👤 Test user ID: ${CONFIG.TEST_USER_ID}`);
  console.log(`🌐 Supabase URL: ${CONFIG.SUPABASE_URL}`);
  
  try {
    await testPredictIllness();
    await testLogToHedera();
    await testHealthStats();
    await testEdgeCases();
    await testPerformance();
    
  } catch (error) {
    console.error('❌ Test suite error:', error);
  }
  
  // =====================================================
  // FINAL RESULTS
  // =====================================================
  
  logSection('FINAL TEST RESULTS');
  
  console.log(`📊 Total Tests: ${testResults.total}`);
  console.log(`✅ Passed: ${testResults.passed}`);
  console.log(`❌ Failed: ${testResults.failed}`);
  console.log(`📈 Success Rate: ${((testResults.passed / testResults.total) * 100).toFixed(1)}%`);
  
  if (testResults.errors.length > 0) {
    console.log('\n❌ FAILED TESTS:');
    testResults.errors.forEach(error => {
      console.log(`   • ${error.test}: ${error.details}`);
    });
  }
  
  if (testResults.predictions.length > 0) {
    console.log('\n🎯 PREDICTIONS CREATED:');
    testResults.predictions.forEach((pred, i) => {
      console.log(`   ${i + 1}. ${pred.illness} (${pred.confidencePercentage} confidence)`);
    });
  }
  
  if (testResults.hederaTransactions.length > 0) {
    console.log('\n🔗 HEDERA TRANSACTIONS:');
    testResults.hederaTransactions.forEach((tx, i) => {
      console.log(`   ${i + 1}. ${tx}`);
    });
  }
  
  // Overall assessment
  const successRate = (testResults.passed / testResults.total) * 100;
  
  if (successRate >= 90) {
    console.log('\n🎉 EXCELLENT! Your Edge Functions are working perfectly!');
    console.log('✅ Ready to integrate with Flutter app');
  } else if (successRate >= 70) {
    console.log('\n⚠️  GOOD! Most functions work, but some issues need fixing');
    console.log('🔧 Review failed tests before Flutter integration');
  } else {
    console.log('\n❌ NEEDS WORK! Multiple issues detected');
    console.log('🛠️  Fix critical issues before proceeding');
  }
  
  console.log(`\n📅 Test completed at: ${new Date().toISOString()}`);
}

// =====================================================
// RUN TESTS
// =====================================================

if (require.main === module) {
  runAllTests().catch(console.error);
}

module.exports = {
  runAllTests,
  CONFIG,
  testResults
};
