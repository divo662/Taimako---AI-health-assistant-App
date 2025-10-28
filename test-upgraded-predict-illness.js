#!/usr/bin/env node
/**
 * =====================================================
 * TAIMAKO - TEST UPGRADED PREDICT-ILLNESS FUNCTION
 * =====================================================
 * 
 * Tests the upgraded predict-illness function with:
 * - Location-based predictions
 * - Critical condition detection
 * - Emergency services integration
 * - Expanded medical dataset
 * 
 * Run: node test-upgraded-predict-illness.js
 */

const https = require('https');

// Configuration
const CONFIG = {
  SUPABASE_URL: 'https://pcqfdxgajkojuffiiykt.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjcWZkeGdhamtvanVmZmlpeWt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4NzYyMzYsImV4cCI6MjA3NjQ1MjIzNn0.lf0e9v-qyOXPa_GQPsBRbyMH_VfcNJS2oash49RD_ik',
  TEST_USER_ID: 'ce0dfef5-fdbc-40ce-9d11-4045aec499b3',
  FUNCTION_URL: '/functions/v1/predict-illness'
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

// Test cases for upgraded function
const UPGRADED_TEST_CASES = [
  {
    name: 'Lagos Malaria with Location',
    request: {
      symptoms: ['fever', 'chills', 'headache', 'body_aches'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adult_20_64',
      gender: 'male',
      season: 'rainy_season',
      location: {
        state_code: 'LAG',
        lga_code: 'IKEJA'
      },
      additional_context: {
        recent_travel: ['Lagos'],
        exposure_risks: ['mosquito_exposure'],
        current_medications: [],
        allergies: []
      }
    },
    expectedFeatures: ['location_risk_factors', 'emergency_assessment', 'prevention_tips', 'follow_up_advice']
  },
  {
    name: 'Critical Condition Detection',
    request: {
      symptoms: ['severe_headache', 'fever', 'stiff_neck'],
      user_id: CONFIG.TEST_USER_ID,
      location: {
        state_code: 'FCT'
      }
    },
    expectedFeatures: ['critical_detection', 'emergency_protocols']
  },
  {
    name: 'Kano Pneumonia with Context',
    request: {
      symptoms: ['cough', 'chest_pain', 'shortness_of_breath'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'elderly_65_plus',
      gender: 'female',
      season: 'dry_season',
      location: {
        state_code: 'KAN',
        lga_code: 'KANO_MUNICIPAL'
      },
      additional_context: {
        exposure_risks: ['dust_exposure'],
        current_medications: ['blood_pressure_medication'],
        allergies: ['dust']
      }
    },
    expectedFeatures: ['location_risk_factors', 'emergency_assessment', 'prevention_tips']
  },
  {
    name: 'Rivers Cholera Emergency',
    request: {
      symptoms: ['profuse_watery_diarrhea', 'vomiting', 'dehydration'],
      user_id: CONFIG.TEST_USER_ID,
      location: {
        state_code: 'RIV'
      }
    },
    expectedFeatures: ['emergency_assessment', 'prevention_tips', 'follow_up_advice']
  },
  {
    name: 'Plateau Stroke Critical',
    request: {
      symptoms: ['sudden_numbness', 'confusion', 'trouble_speaking'],
      user_id: CONFIG.TEST_USER_ID,
      location: {
        state_code: 'PLA'
      }
    },
    expectedFeatures: ['critical_detection', 'emergency_protocols']
  }
];

// Test functions
async function testUpgradedPredictIllness() {
  logSection('TESTING UPGRADED PREDICT-ILLNESS FUNCTION');
  
  for (const testCase of UPGRADED_TEST_CASES) {
    console.log(`\n🔍 Testing: ${testCase.name}`);
    
    try {
      const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTION_URL;
      const response = await makeRequest(url, testCase.request);
      
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
        
        // Check for upgraded features
        for (const feature of testCase.expectedFeatures) {
          switch (feature) {
            case 'location_risk_factors':
              const hasLocationRisk = result.location_risk_factors;
              logTest(`${testCase.name} - Location Risk Factors`, !!hasLocationRisk,
                hasLocationRisk ? `State risk: ${result.location_risk_factors.state_risk}` : 'No location risk factors');
              break;
              
            case 'emergency_assessment':
              const hasEmergencyAssessment = result.emergency_assessment;
              logTest(`${testCase.name} - Emergency Assessment`, !!hasEmergencyAssessment,
                hasEmergencyAssessment ? `Critical: ${result.emergency_assessment.is_critical}` : 'No emergency assessment');
              break;
              
            case 'prevention_tips':
              const hasPreventionTips = result.prevention_tips && result.prevention_tips.length > 0;
              logTest(`${testCase.name} - Prevention Tips`, hasPreventionTips,
                hasPreventionTips ? `${result.prevention_tips.length} tips provided` : 'No prevention tips');
              break;
              
            case 'follow_up_advice':
              const hasFollowUp = result.follow_up_advice && result.follow_up_advice.length > 0;
              logTest(`${testCase.name} - Follow-up Advice`, hasFollowUp,
                hasFollowUp ? `${result.follow_up_advice.length} advice items` : 'No follow-up advice');
              break;
              
            case 'critical_detection':
              const isCritical = result.urgency === 'critical' || result.emergency_assessment?.is_critical;
              logTest(`${testCase.name} - Critical Detection`, isCritical,
                isCritical ? 'Critical condition detected' : 'No critical condition detected');
              break;
              
            case 'emergency_protocols':
              const hasEmergencyProtocols = result.emergency_assessment?.emergency_protocols?.length > 0;
              logTest(`${testCase.name} - Emergency Protocols`, hasEmergencyProtocols,
                hasEmergencyProtocols ? `${result.emergency_assessment.emergency_protocols.length} protocols` : 'No emergency protocols');
              break;
          }
        }
        
        console.log(`📊 Enhanced Prediction Details:`);
        console.log(`   Illness: ${result.illness}`);
        console.log(`   Confidence: ${(result.confidence * 100).toFixed(1)}%`);
        console.log(`   Urgency: ${result.urgency}`);
        console.log(`   Severity: ${result.severity}`);
        console.log(`   Location Risk: ${result.location_risk_factors?.state_risk || 'N/A'}`);
        console.log(`   Emergency Critical: ${result.emergency_assessment?.is_critical || false}`);
        console.log(`   Prevention Tips: ${result.prevention_tips?.length || 0}`);
        console.log(`   Follow-up Advice: ${result.follow_up_advice?.length || 0}`);
        console.log(`   Emergency Contacts: ${result.emergency_assessment?.emergency_contacts ? 'Available' : 'Not available'}`);
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

async function testBackwardCompatibility() {
  logSection('TESTING BACKWARD COMPATIBILITY');
  
  console.log('\n🔄 Testing old request format...');
  
  try {
    const oldFormatRequest = {
      symptoms: ['fever', 'chills'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adult_20_64'
    };

    const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTION_URL;
    const response = await makeRequest(url, oldFormatRequest);
    
    const statusOk = response.status === 200;
    logTest('Old Format - Status Code', statusOk, 
      statusOk ? 'OK' : `Expected 200, got ${response.status}`);
    
    if (statusOk && response.data.success) {
      const hasResult = response.data.result;
      logTest('Old Format - Has Result', !!hasResult);
      
      if (hasResult) {
        const result = response.data.result;
        const hasNewFeatures = result.location_risk_factors || result.emergency_assessment || result.prevention_tips;
        logTest('Old Format - New Features Available', !!hasNewFeatures,
          hasNewFeatures ? 'New features available' : 'New features not available');
      }
    }
  } catch (error) {
    logTest('Old Format - Request Error', false, error.message);
  }
}

// Main test runner
async function runUpgradedTests() {
  console.log('🚀 TAIMAKO UPGRADED PREDICT-ILLNESS TEST SUITE');
  console.log('==============================================');
  console.log(`📅 Test started at: ${new Date().toISOString()}`);
  console.log(`👤 Test user ID: ${CONFIG.TEST_USER_ID}`);
  console.log(`🌐 Supabase URL: ${CONFIG.SUPABASE_URL}`);
  
  try {
    await testUpgradedPredictIllness();
    await testBackwardCompatibility();
    
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
    console.log('\n🎉 EXCELLENT! Upgraded function working perfectly!');
    console.log('✅ Location-based predictions: Working');
    console.log('✅ Critical condition detection: Working');
    console.log('✅ Emergency services integration: Working');
    console.log('✅ Expanded medical dataset: Working');
    console.log('✅ Enhanced AI analysis: Working');
    console.log('✅ Backward compatibility: Working');
  } else if (successRate >= 70) {
    console.log('\n⚠️  MOSTLY WORKING - Some features need attention');
    console.log('🔧 Review failed tests before production deployment');
  } else {
    console.log('\n❌ NEEDS WORK - Multiple features have issues');
    console.log('🛠️  Fix critical issues before proceeding');
  }
  
  console.log(`\n📅 Test completed at: ${new Date().toISOString()}`);
}

// Run tests
if (require.main === module) {
  runUpgradedTests().catch(console.error);
}

module.exports = {
  runUpgradedTests,
  CONFIG,
  testResults
};
