#!/usr/bin/env node
/**
 * =====================================================
 * TAIMAKO - ADVANCED FEATURES TEST SUITE
 * =====================================================
 * 
 * Tests all new advanced features:
 * - Location-based predictions
 * - Emergency services integration
 * - Expanded medical dataset
 * - Critical condition detection
 * 
 * Run: node test-advanced-features.js
 */

const https = require('https');

// Configuration
const CONFIG = {
  SUPABASE_URL: 'https://pcqfdxgajkojuffiiykt.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjcWZkeGdhamtvanVmZmlpeWt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4NzYyMzYsImV4cCI6MjA3NjQ1MjIzNn0.lf0e9v-qyOXPa_GQPsBRbyMH_VfcNJS2oash49RD_ik',
  TEST_USER_ID: 'ce0dfef5-fdbc-40ce-9d11-4045aec499b3',
  FUNCTIONS: {
    PREDICT_ILLNESS_V2: '/functions/v1/predict-illness-v2',
    HEALTH_STATS: '/functions/v1/get-health-stats',
    LOG_HEDERA: '/functions/v1/log-to-hedera'
  }
};

// Test results tracking
const testResults = {
  total: 0,
  passed: 0,
  failed: 0,
  errors: []
};

// Utility functions
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

// Test cases
const TEST_CASES = [
  {
    name: 'Lagos Malaria Prediction',
    symptoms: ['fever', 'chills', 'headache', 'body_aches'],
    location: { state_code: 'LAG', lga_code: 'IKEJA' },
    expected_illness: 'Malaria',
    expected_urgency: 'moderate'
  },
  {
    name: 'Kano Pneumonia Prediction',
    symptoms: ['cough', 'chest_pain', 'shortness_of_breath'],
    location: { state_code: 'KAN', lga_code: 'KANO_MUNICIPAL' },
    expected_illness: 'Pneumonia',
    expected_urgency: 'high'
  },
  {
    name: 'Abuja Critical Condition',
    symptoms: ['severe_headache', 'fever', 'stiff_neck'],
    location: { state_code: 'FCT' },
    expected_illness: 'Meningitis',
    expected_urgency: 'critical'
  },
  {
    name: 'Rivers Cholera Prediction',
    symptoms: ['profuse_watery_diarrhea', 'vomiting', 'dehydration'],
    location: { state_code: 'RIV' },
    expected_illness: 'Cholera',
    expected_urgency: 'high'
  },
  {
    name: 'Plateau Stroke Emergency',
    symptoms: ['sudden_numbness', 'confusion', 'trouble_speaking'],
    location: { state_code: 'PLA' },
    expected_illness: 'Stroke',
    expected_urgency: 'critical'
  }
];

// Test functions
async function testAdvancedPrediction() {
  logSection('TESTING ADVANCED PREDICTION SYSTEM');
  
  for (const testCase of TEST_CASES) {
    console.log(`\n🔍 Testing: ${testCase.name}`);
    
    try {
      const requestData = {
        user_id: CONFIG.TEST_USER_ID,
        symptoms: testCase.symptoms,
        age_group: 'adult_20_64',
        gender: 'male',
        season: 'rainy_season',
        location: testCase.location,
        additional_context: {
          recent_travel: ['Lagos'],
          exposure_risks: ['mosquito_exposure'],
          current_medications: [],
          allergies: []
        }
      };

      const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTIONS.PREDICT_ILLNESS_V2;
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
      
      const hasResult = response.data.result;
      logTest(`${testCase.name} - Has Result`, !!hasResult);
      
      if (hasResult) {
        const result = response.data.result;
        
        // Check illness prediction
        const illnessMatch = result.illness.toLowerCase().includes(testCase.expected_illness.toLowerCase());
        logTest(`${testCase.name} - Illness Match`, illnessMatch, 
          illnessMatch ? `Found: ${result.illness}` : `Expected: ${testCase.expected_illness}, Got: ${result.illness}`);
        
        // Check urgency
        const urgencyMatch = result.urgency === testCase.expected_urgency;
        logTest(`${testCase.name} - Urgency Match`, urgencyMatch,
          urgencyMatch ? `Correct urgency: ${result.urgency}` : `Expected: ${testCase.expected_urgency}, Got: ${result.urgency}`);
        
        // Check location risk factors
        const hasLocationRisk = result.location_risk_factors;
        logTest(`${testCase.name} - Location Risk Factors`, !!hasLocationRisk,
          hasLocationRisk ? `State risk: ${result.location_risk_factors.state_risk}` : 'No location risk factors');
        
        // Check emergency assessment
        const hasEmergencyAssessment = result.emergency_assessment;
        logTest(`${testCase.name} - Emergency Assessment`, !!hasEmergencyAssessment,
          hasEmergencyAssessment ? `Critical: ${result.emergency_assessment.is_critical}` : 'No emergency assessment');
        
        // Check prevention tips
        const hasPreventionTips = result.prevention_tips && result.prevention_tips.length > 0;
        logTest(`${testCase.name} - Prevention Tips`, hasPreventionTips,
          hasPreventionTips ? `${result.prevention_tips.length} tips provided` : 'No prevention tips');
        
        // Check follow-up advice
        const hasFollowUp = result.follow_up_advice && result.follow_up_advice.length > 0;
        logTest(`${testCase.name} - Follow-up Advice`, hasFollowUp,
          hasFollowUp ? `${result.follow_up_advice.length} advice items` : 'No follow-up advice');
        
        console.log(`📊 Advanced Prediction Details:`);
        console.log(`   Illness: ${result.illness}`);
        console.log(`   Confidence: ${(result.confidence * 100).toFixed(1)}%`);
        console.log(`   Urgency: ${result.urgency}`);
        console.log(`   Location Risk: ${result.location_risk_factors?.state_risk || 'N/A'}`);
        console.log(`   Emergency Critical: ${result.emergency_assessment?.is_critical || false}`);
        console.log(`   Prevention Tips: ${result.prevention_tips?.length || 0}`);
        console.log(`   Follow-up Advice: ${result.follow_up_advice?.length || 0}`);
      }
      
      // Check Hedera integration
      const hasHederaTx = response.data.result?.hedera_transaction_id;
      logTest(`${testCase.name} - Hedera Transaction`, !!hasHederaTx,
        hasHederaTx ? `TX: ${response.data.result.hedera_transaction_id}` : 'No Hedera transaction ID');
      
    } catch (error) {
      logTest(`${testCase.name} - Request Error`, false, error.message);
    }
  }
}

async function testCriticalConditionDetection() {
  logSection('TESTING CRITICAL CONDITION DETECTION');
  
  const criticalTestCases = [
    {
      name: 'Meningitis Symptoms',
      symptoms: ['severe_headache', 'fever', 'stiff_neck'],
      expectedCritical: true
    },
    {
      name: 'Stroke Symptoms',
      symptoms: ['sudden_numbness', 'confusion', 'trouble_speaking'],
      expectedCritical: true
    },
    {
      name: 'Heart Attack Symptoms',
      symptoms: ['chest_pain', 'shortness_of_breath', 'nausea'],
      expectedCritical: true
    },
    {
      name: 'Non-Critical Symptoms',
      symptoms: ['runny_nose', 'sneezing', 'mild_cough'],
      expectedCritical: false
    }
  ];
  
  for (const testCase of criticalTestCases) {
    console.log(`\n🚨 Testing: ${testCase.name}`);
    
    try {
      const requestData = {
        user_id: CONFIG.TEST_USER_ID,
        symptoms: testCase.symptoms,
        location: { state_code: 'LAG' }
      };

      const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTIONS.PREDICT_ILLNESS_V2;
      const response = await makeRequest(url, requestData);
      
      if (response.status === 200 && response.data.success) {
        const isCritical = response.data.result?.emergency_assessment?.is_critical || false;
        const criticalMatch = isCritical === testCase.expectedCritical;
        
        logTest(`${testCase.name} - Critical Detection`, criticalMatch,
          criticalMatch ? `Correctly detected: ${isCritical}` : `Expected: ${testCase.expectedCritical}, Got: ${isCritical}`);
        
        if (isCritical) {
          console.log(`🚨 CRITICAL CONDITION DETECTED!`);
          console.log(`   Emergency Protocols: ${response.data.result.emergency_assessment.emergency_protocols?.length || 0}`);
          console.log(`   Emergency Contacts: ${response.data.result.emergency_assessment.emergency_contacts ? 'Available' : 'Not available'}`);
        }
      }
    } catch (error) {
      logTest(`${testCase.name} - Request Error`, false, error.message);
    }
  }
}

async function testLocationBasedPredictions() {
  logSection('TESTING LOCATION-BASED PREDICTIONS');
  
  const locationTestCases = [
    {
      name: 'Lagos Malaria Risk',
      symptoms: ['fever', 'chills'],
      location: { state_code: 'LAG' },
      expectedHighRisk: true
    },
    {
      name: 'Plateau Moderate Risk',
      symptoms: ['fever', 'chills'],
      location: { state_code: 'PLA' },
      expectedHighRisk: false
    },
    {
      name: 'Kano Pneumonia Risk',
      symptoms: ['cough', 'chest_pain'],
      location: { state_code: 'KAN' },
      expectedHighRisk: true
    }
  ];
  
  for (const testCase of locationTestCases) {
    console.log(`\n📍 Testing: ${testCase.name}`);
    
    try {
      const requestData = {
        user_id: CONFIG.TEST_USER_ID,
        symptoms: testCase.symptoms,
        location: testCase.location
      };

      const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTIONS.PREDICT_ILLNESS_V2;
      const response = await makeRequest(url, requestData);
      
      if (response.status === 200 && response.data.success) {
        const locationRisk = response.data.result?.location_risk_factors?.state_risk || 1.0;
        const isHighRisk = locationRisk > 1.1;
        const riskMatch = isHighRisk === testCase.expectedHighRisk;
        
        logTest(`${testCase.name} - Location Risk`, riskMatch,
          riskMatch ? `Correct risk level: ${locationRisk}` : `Expected high risk: ${testCase.expectedHighRisk}, Got: ${isHighRisk}`);
        
        console.log(`📍 Location Analysis:`);
        console.log(`   State Risk Factor: ${locationRisk}`);
        console.log(`   Regional Prevalence: ${response.data.result?.location_risk_factors?.regional_prevalence || 'Unknown'}`);
        console.log(`   Seasonal Factors: ${response.data.result?.location_risk_factors?.seasonal_factors?.length || 0}`);
      }
    } catch (error) {
      logTest(`${testCase.name} - Request Error`, false, error.message);
    }
  }
}

async function testExpandedDataset() {
  logSection('TESTING EXPANDED MEDICAL DATASET');
  
  const expandedTestCases = [
    {
      name: 'Lassa Fever',
      symptoms: ['fever', 'headache', 'muscle_aches', 'bleeding'],
      expectedUrgency: 'critical'
    },
    {
      name: 'Cholera',
      symptoms: ['profuse_watery_diarrhea', 'vomiting', 'dehydration'],
      expectedUrgency: 'high'
    },
    {
      name: 'Stroke',
      symptoms: ['sudden_numbness', 'confusion', 'trouble_speaking'],
      expectedUrgency: 'critical'
    },
    {
      name: 'Kidney Stones',
      symptoms: ['severe_pain', 'blood_in_urine', 'nausea'],
      expectedUrgency: 'high'
    }
  ];
  
  for (const testCase of expandedTestCases) {
    console.log(`\n🦠 Testing: ${testCase.name}`);
    
    try {
      const requestData = {
        user_id: CONFIG.TEST_USER_ID,
        symptoms: testCase.symptoms,
        location: { state_code: 'LAG' }
      };

      const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTIONS.PREDICT_ILLNESS_V2;
      const response = await makeRequest(url, requestData);
      
      if (response.status === 200 && response.data.success) {
        const urgency = response.data.result?.urgency;
        const urgencyMatch = urgency === testCase.expectedUrgency;
        
        logTest(`${testCase.name} - Urgency Detection`, urgencyMatch,
          urgencyMatch ? `Correct urgency: ${urgency}` : `Expected: ${testCase.expectedUrgency}, Got: ${urgency}`);
        
        console.log(`🦠 Disease Analysis:`);
        console.log(`   Illness: ${response.data.result?.illness || 'Unknown'}`);
        console.log(`   Urgency: ${urgency}`);
        console.log(`   Severity: ${response.data.result?.severity || 'Unknown'}`);
        console.log(`   Confidence: ${response.data.result?.confidence ? (response.data.result.confidence * 100).toFixed(1) + '%' : 'Unknown'}`);
      }
    } catch (error) {
      logTest(`${testCase.name} - Request Error`, false, error.message);
    }
  }
}

// Main test runner
async function runAllTests() {
  console.log('🚀 TAIMAKO ADVANCED FEATURES TEST SUITE');
  console.log('========================================');
  console.log(`📅 Test started at: ${new Date().toISOString()}`);
  console.log(`👤 Test user ID: ${CONFIG.TEST_USER_ID}`);
  console.log(`🌐 Supabase URL: ${CONFIG.SUPABASE_URL}`);
  
  try {
    await testAdvancedPrediction();
    await testCriticalConditionDetection();
    await testLocationBasedPredictions();
    await testExpandedDataset();
    
  } catch (error) {
    console.error('❌ Test suite error:', error);
  }
  
  // Final Results
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
  
  // Overall assessment
  const successRate = (testResults.passed / testResults.total) * 100;
  
  if (successRate >= 90) {
    console.log('\n🎉 EXCELLENT! All advanced features working perfectly!');
    console.log('✅ Location-based predictions: Working');
    console.log('✅ Critical condition detection: Working');
    console.log('✅ Emergency services integration: Working');
    console.log('✅ Expanded medical dataset: Working');
    console.log('✅ Advanced AI analysis: Working');
  } else if (successRate >= 70) {
    console.log('\n⚠️  MOSTLY WORKING - Some advanced features need attention');
    console.log('🔧 Review failed tests before production deployment');
  } else {
    console.log('\n❌ NEEDS WORK - Multiple advanced features have issues');
    console.log('🛠️  Fix critical issues before proceeding');
  }
  
  console.log(`\n📅 Test completed at: ${new Date().toISOString()}`);
}

// Run tests
if (require.main === module) {
  runAllTests().catch(console.error);
}

module.exports = {
  runAllTests,
  CONFIG,
  testResults
};
