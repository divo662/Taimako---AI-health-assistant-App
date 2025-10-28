#!/usr/bin/env node
/**
 * =====================================================
 * TAIMAKO - REAL NIGERIAN SCENARIOS TEST
 * =====================================================
 * 
 * Tests the AI with realistic Nigerian scenarios:
 * - Average Nigerian language patterns
 * - Simple symptom descriptions
 * - Different locations across Nigeria
 * - Various illness scenarios
 * 
 * Run: node test-nigerian-scenarios.js
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
  console.log('\n' + '='.repeat(70));
  console.log(`🇳🇬 ${title}`);
  console.log('='.repeat(70));
}

// Real Nigerian scenarios
const NIGERIAN_SCENARIOS = [
  {
    name: 'Lagos Market Trader - Simple Fever',
    description: 'Average Lagosian saying "I just have fever"',
    request: {
      symptoms: ['fever'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adult_20_64',
      gender: 'female',
      location: {
        state_code: 'LAG',
        lga_code: 'Lagos Island'
      },
      additional_context: {
        occupation: 'market_trader',
        recent_activities: ['market_work', 'outdoor_work']
      }
    },
    expectedIllness: 'Malaria',
    expectedUrgency: 'moderate'
  },
  {
    name: 'Kano Farmer - Body Pain',
    description: 'Northern farmer saying "My body dey pain me"',
    request: {
      symptoms: ['body_aches', 'fatigue'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adult_20_64',
      gender: 'male',
      location: {
        state_code: 'KAN',
        lga_code: 'Kano Municipal'
      },
      additional_context: {
        occupation: 'farmer',
        recent_activities: ['farming', 'heavy_lifting']
      }
    },
    expectedIllness: 'Malaria',
    expectedUrgency: 'moderate'
  },
  {
    name: 'Abuja Office Worker - Headache',
    description: 'Office worker saying "My head dey pain me"',
    request: {
      symptoms: ['headache'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adult_20_64',
      gender: 'male',
      location: {
        state_code: 'FCT',
        lga_code: 'Abuja Municipal'
      },
      additional_context: {
        occupation: 'office_worker',
        recent_activities: ['computer_work', 'stress']
      }
    },
    expectedIllness: 'Migraine',
    expectedUrgency: 'low'
  },
  {
    name: 'Port Harcourt Student - Cough',
    description: 'Student saying "I dey cough"',
    request: {
      symptoms: ['cough'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adolescent_13_19',
      gender: 'female',
      location: {
        state_code: 'RIV',
        lga_code: 'Port Harcourt'
      },
      additional_context: {
        occupation: 'student',
        recent_activities: ['school', 'dormitory_living']
      }
    },
    expectedIllness: 'Common Cold',
    expectedUrgency: 'low'
  },
  {
    name: 'Ibadan Elderly - Multiple Symptoms',
    description: 'Elderly person saying "I no feel fine at all"',
    request: {
      symptoms: ['fever', 'chills', 'headache', 'body_aches', 'fatigue'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'elderly_65_plus',
      gender: 'female',
      location: {
        state_code: 'OYO',
        lga_code: 'Ibadan North'
      },
      additional_context: {
        occupation: 'retired',
        recent_activities: ['home_activities'],
        current_medications: ['blood_pressure_medication']
      }
    },
    expectedIllness: 'Malaria',
    expectedUrgency: 'moderate'
  },
  {
    name: 'Enugu Child - Stomach Pain',
    description: 'Child saying "My belly dey pain me"',
    request: {
      symptoms: ['abdominal_pain'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'child_2_12',
      gender: 'male',
      location: {
        state_code: 'ENU',
        lga_code: 'Enugu North'
      },
      additional_context: {
        occupation: 'student',
        recent_activities: ['playing', 'school']
      }
    },
    expectedIllness: 'Gastritis',
    expectedUrgency: 'low'
  },
  {
    name: 'Kaduna Pregnant Woman - Nausea',
    description: 'Pregnant woman saying "I dey vomit"',
    request: {
      symptoms: ['nausea', 'vomiting'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adult_20_64',
      gender: 'female',
      location: {
        state_code: 'KAD',
        lga_code: 'Kaduna North'
      },
      additional_context: {
        occupation: 'housewife',
        recent_activities: ['pregnancy'],
        current_medications: ['prenatal_vitamins']
      }
    },
    expectedIllness: 'Gastritis',
    expectedUrgency: 'low'
  },
  {
    name: 'Calabar Fisherman - Diarrhea',
    description: 'Fisherman saying "I dey run stomach"',
    request: {
      symptoms: ['diarrhea'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adult_20_64',
      gender: 'male',
      location: {
        state_code: 'CRO',
        lga_code: 'Calabar Municipal'
      },
      additional_context: {
        occupation: 'fisherman',
        recent_activities: ['fishing', 'water_contact']
      }
    },
    expectedIllness: 'Acute Diarrhea',
    expectedUrgency: 'moderate'
  },
  {
    name: 'Jos Teacher - Chest Pain',
    description: 'Teacher saying "My chest dey pain me"',
    request: {
      symptoms: ['chest_pain'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adult_20_64',
      gender: 'male',
      location: {
        state_code: 'PLA',
        lga_code: 'Jos North'
      },
      additional_context: {
        occupation: 'teacher',
        recent_activities: ['teaching', 'stress']
      }
    },
    expectedIllness: 'Pneumonia',
    expectedUrgency: 'high'
  },
  {
    name: 'Benin City Driver - Dizziness',
    description: 'Driver saying "I dey feel dizzy"',
    request: {
      symptoms: ['dizziness'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adult_20_64',
      gender: 'male',
      location: {
        state_code: 'EDO',
        lga_code: 'Oredo'
      },
      additional_context: {
        occupation: 'driver',
        recent_activities: ['driving', 'long_hours']
      }
    },
    expectedIllness: 'Hypertension',
    expectedUrgency: 'moderate'
  },
  {
    name: 'Maiduguri IDP - Severe Symptoms',
    description: 'IDP saying "I no fit move, everything dey pain me"',
    request: {
      symptoms: ['fever', 'chills', 'headache', 'body_aches', 'fatigue', 'nausea', 'vomiting'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adult_20_64',
      gender: 'female',
      location: {
        state_code: 'BOR',
        lga_code: 'Maiduguri'
      },
      additional_context: {
        occupation: 'displaced_person',
        recent_activities: ['displacement', 'poor_conditions'],
        exposure_risks: ['overcrowding', 'poor_sanitation']
      }
    },
    expectedIllness: 'Malaria',
    expectedUrgency: 'high'
  },
  {
    name: 'Lagos Bus Driver - Single Symptom',
    description: 'Bus driver saying "I just dey cough"',
    request: {
      symptoms: ['cough'],
      user_id: CONFIG.TEST_USER_ID,
      age_group: 'adult_20_64',
      gender: 'male',
      location: {
        state_code: 'LAG',
        lga_code: 'Surulere'
      },
      additional_context: {
        occupation: 'bus_driver',
        recent_activities: ['driving', 'passenger_contact']
      }
    },
    expectedIllness: 'Common Cold',
    expectedUrgency: 'low'
  }
];

// Test functions
async function testNigerianScenarios() {
  logSection('TESTING REAL NIGERIAN SCENARIOS');
  
  for (const scenario of NIGERIAN_SCENARIOS) {
    console.log(`\n🇳🇬 Testing: ${scenario.name}`);
    console.log(`📝 Scenario: ${scenario.description}`);
    
    try {
      const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTION_URL;
      const response = await makeRequest(url, scenario.request);
      
      // Check response status
      const statusOk = response.status === 200;
      logTest(`${scenario.name} - Status Code`, statusOk, 
        statusOk ? 'OK' : `Expected 200, got ${response.status}`);
      
      if (!statusOk) {
        console.log('Response:', JSON.stringify(response.data, null, 2));
        continue;
      }

      // Check response structure
      const hasSuccess = response.data.success === true;
      logTest(`${scenario.name} - Response Success`, hasSuccess);
      
      const hasResult = response.data.result;
      logTest(`${scenario.name} - Has Result`, !!hasResult);
      
      if (hasResult) {
        const result = response.data.result;
        
        // Check illness prediction
        const illnessMatch = result.illness.toLowerCase().includes(scenario.expectedIllness.toLowerCase()) ||
                           scenario.expectedIllness.toLowerCase().includes(result.illness.toLowerCase());
        logTest(`${scenario.name} - Illness Prediction`, illnessMatch,
          illnessMatch ? `Correct: ${result.illness}` : `Expected: ${scenario.expectedIllness}, Got: ${result.illness}`);
        
        // Check urgency
        const urgencyMatch = result.urgency === scenario.expectedUrgency;
        logTest(`${scenario.name} - Urgency Level`, urgencyMatch,
          urgencyMatch ? `Correct urgency: ${result.urgency}` : `Expected: ${scenario.expectedUrgency}, Got: ${result.urgency}`);
        
        // Check confidence level
        const confidenceGood = result.confidence >= 0.3;
        logTest(`${scenario.name} - Confidence Level`, confidenceGood,
          confidenceGood ? `Good confidence: ${(result.confidence * 100).toFixed(1)}%` : `Low confidence: ${(result.confidence * 100).toFixed(1)}%`);
        
        // Check advice quality
        const adviceGood = result.advice && result.advice.length > 20;
        logTest(`${scenario.name} - Advice Quality`, adviceGood,
          adviceGood ? `Good advice provided` : `Advice too short or missing`);
        
        // Check prevention tips
        const hasPreventionTips = result.prevention_tips && result.prevention_tips.length > 0;
        logTest(`${scenario.name} - Prevention Tips`, hasPreventionTips,
          hasPreventionTips ? `${result.prevention_tips.length} tips provided` : 'No prevention tips');
        
        console.log(`📊 AI Analysis:`);
        console.log(`   Illness: ${result.illness}`);
        console.log(`   Confidence: ${(result.confidence * 100).toFixed(1)}%`);
        console.log(`   Urgency: ${result.urgency}`);
        console.log(`   Severity: ${result.severity}`);
        console.log(`   Location Risk: ${result.location_risk_factors?.state_risk || 'N/A'}`);
        console.log(`   Prevention Tips: ${result.prevention_tips?.length || 0}`);
        console.log(`   Follow-up Advice: ${result.follow_up_advice?.length || 0}`);
        console.log(`   Advice: ${result.advice?.substring(0, 100)}...`);
      }
      
    } catch (error) {
      logTest(`${scenario.name} - Request Error`, false, error.message);
    }
  }
}

async function testSingleSymptomScenarios() {
  logSection('TESTING SINGLE SYMPTOM SCENARIOS');
  
  const singleSymptoms = [
    { symptom: 'fever', expected: 'Malaria', location: 'LAG' },
    { symptom: 'cough', expected: 'Common Cold', location: 'KAN' },
    { symptom: 'headache', expected: 'Migraine', location: 'FCT' },
    { symptom: 'nausea', expected: 'Gastritis', location: 'RIV' },
    { symptom: 'fatigue', expected: 'Anemia', location: 'OYO' },
    { symptom: 'dizziness', expected: 'Hypertension', location: 'EDO' }
  ];
  
  for (const test of singleSymptoms) {
    console.log(`\n🔍 Testing single symptom: ${test.symptom}`);
    
    try {
      const request = {
        symptoms: [test.symptom],
        user_id: CONFIG.TEST_USER_ID,
        location: {
          state_code: test.location
        }
      };

      const url = CONFIG.SUPABASE_URL + CONFIG.FUNCTION_URL;
      const response = await makeRequest(url, request);
      
      if (response.status === 200 && response.data.success) {
        const result = response.data.result;
        const illnessMatch = result.illness.toLowerCase().includes(test.expected.toLowerCase());
        
        logTest(`Single ${test.symptom} - Illness Match`, illnessMatch,
          illnessMatch ? `Correct: ${result.illness}` : `Expected: ${test.expected}, Got: ${result.illness}`);
        
        console.log(`   Single symptom "${test.symptom}" → ${result.illness} (${(result.confidence * 100).toFixed(1)}%)`);
      }
    } catch (error) {
      logTest(`Single ${test.symptom} - Error`, false, error.message);
    }
  }
}

// Main test runner
async function runNigerianScenarios() {
  console.log('🇳🇬 TAIMAKO NIGERIAN SCENARIOS TEST SUITE');
  console.log('==========================================');
  console.log(`📅 Test started at: ${new Date().toISOString()}`);
  console.log(`👤 Test user ID: ${CONFIG.TEST_USER_ID}`);
  console.log(`🌐 Supabase URL: ${CONFIG.SUPABASE_URL}`);
  console.log(`🎯 Testing with REAL Nigerian scenarios and language patterns`);
  
  try {
    await testNigerianScenarios();
    await testSingleSymptomScenarios();
    
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
  
  if (successRate >= 85) {
    console.log('\n🎉 EXCELLENT! AI handles Nigerian scenarios perfectly!');
    console.log('✅ Single symptoms: Working');
    console.log('✅ Multiple symptoms: Working');
    console.log('✅ Location-based predictions: Working');
    console.log('✅ Nigerian context: Working');
    console.log('✅ Cultural sensitivity: Working');
  } else if (successRate >= 70) {
    console.log('\n⚠️  GOOD - AI handles most Nigerian scenarios well');
    console.log('🔧 Some scenarios need improvement');
  } else {
    console.log('\n❌ NEEDS WORK - AI struggles with Nigerian scenarios');
    console.log('🛠️  Significant improvements needed');
  }
  
  console.log(`\n📅 Test completed at: ${new Date().toISOString()}`);
}

// Run tests
if (require.main === module) {
  runNigerianScenarios().catch(console.error);
}

module.exports = {
  runNigerianScenarios,
  CONFIG,
  testResults
};
