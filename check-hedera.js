#!/usr/bin/env node
/**
 * =====================================================
 * TAIMAKO - HEDERA TRANSACTION CHECKER
 * =====================================================
 * 
 * This script tests Hedera logging and shows you how to
 * check transactions on the blockchain
 * 
 * Run: node check-hedera.js
 */

const https = require('https');

// Configuration
const SUPABASE_URL = 'https://pcqfdxgajkojuffiiykt.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjcWZkeGdhamtvanVmZmlpeWt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4NzYyMzYsImV4cCI6MjA3NjQ1MjIzNn0.lf0e9v-qyOXPa_GQPsBRbyMH_VfcNJS2oash49RD_ik';
const TEST_USER_ID = 'ce0dfef5-fdbc-40ce-9d11-4045aec499b3';

// Hedera Configuration
const HEDERA_TOPIC_ID = '0.0.7098028';
const HEDERA_ACCOUNT_ID = '0.0.7096886';

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

async function testHederaLogging() {
  console.log('🔗 TAIMAKO HEDERA TRANSACTION CHECKER');
  console.log('=====================================');
  console.log(`👤 Test User: ${TEST_USER_ID}`);
  console.log(`🔗 Hedera Topic: ${HEDERA_TOPIC_ID}`);
  console.log(`👤 Hedera Account: ${HEDERA_ACCOUNT_ID}\n`);

  try {
    // Test 1: Direct Hedera Logging
    console.log('🔗 Testing direct Hedera logging...');
    
    const hederaData = {
      prediction_id: 'test-pred-' + Date.now(),
      user_id: TEST_USER_ID,
      prediction_data: {
        illness: 'Malaria',
        confidence: 0.85,
        urgency: 'moderate',
        severity: 'moderate'
      }
    };

    const hederaResponse = await makeRequest(
      SUPABASE_URL + '/functions/v1/log-to-hedera',
      hederaData
    );

    console.log(`   Status: ${hederaResponse.status}`);
    
    if (hederaResponse.status === 200 && hederaResponse.data.success) {
      const txId = hederaResponse.data.hedera_transaction_id;
      const explorerUrl = hederaResponse.data.explorer_url;
      
      console.log(`   ✅ Hedera transaction successful!`);
      console.log(`   🔗 Transaction ID: ${txId}`);
      console.log(`   🌐 Explorer URL: ${explorerUrl}`);
      
      // Show how to check the transaction
      console.log('\n📋 HOW TO CHECK YOUR HEDERA TRANSACTION:');
      console.log('==========================================');
      console.log(`1. 🌐 Open: ${explorerUrl}`);
      console.log(`2. 🔍 Or search for: ${txId}`);
      console.log(`3. 📊 Or check your topic: https://hashscan.io/testnet/topic/${HEDERA_TOPIC_ID}`);
      console.log(`4. 👤 Or check your account: https://hashscan.io/testnet/account/${HEDERA_ACCOUNT_ID}`);
      
      return txId;
    } else {
      console.log(`   ❌ Hedera logging failed: ${JSON.stringify(hederaResponse.data)}`);
      return null;
    }

  } catch (error) {
    console.error('❌ Error testing Hedera logging:', error.message);
    return null;
  }
}

async function checkExistingTransactions() {
  console.log('\n🔍 CHECKING EXISTING TRANSACTIONS');
  console.log('==================================');
  
  // Check your Hedera topic for existing messages
  console.log(`📊 Your HCS Topic: https://hashscan.io/testnet/topic/${HEDERA_TOPIC_ID}`);
  console.log(`👤 Your Account: https://hashscan.io/testnet/account/${HEDERA_ACCOUNT_ID}`);
  
  console.log('\n📋 WHAT TO LOOK FOR:');
  console.log('===================');
  console.log('✅ Transaction Status: SUCCESS');
  console.log('✅ Message Type: JSON data with prediction info');
  console.log('✅ Timestamp: Recent (within last few minutes)');
  console.log('✅ Fee: Small HBAR amount (usually < 0.01 HBAR)');
}

async function showHederaExplorerGuide() {
  console.log('\n🌐 HEDERA EXPLORER GUIDE');
  console.log('========================');
  
  console.log('📊 MAIN EXPLORER: https://hashscan.io/testnet');
  console.log('');
  console.log('🔍 SEARCH OPTIONS:');
  console.log('• By Transaction ID: Search for "0.0.7096886@1234567890.123456789"');
  console.log('• By Account: https://hashscan.io/testnet/account/0.0.7096886');
  console.log('• By Topic: https://hashscan.io/testnet/topic/0.0.7098028');
  console.log('');
  console.log('📋 WHAT YOU\'LL SEE:');
  console.log('• Transaction details (ID, timestamp, fee)');
  console.log('• Message content (your prediction data)');
  console.log('• Consensus timestamp (blockchain proof)');
  console.log('• Transaction status (SUCCESS/FAILED)');
}

// Main function
async function main() {
  const txId = await testHederaLogging();
  await checkExistingTransactions();
  await showHederaExplorerGuide();
  
  console.log('\n🎉 HEDERA CHECKING COMPLETE!');
  console.log('============================');
  
  if (txId) {
    console.log(`✅ Your transaction is live on Hedera blockchain!`);
    console.log(`🔗 Check it here: https://hashscan.io/testnet/transaction/${txId}`);
  } else {
    console.log('⚠️  No transaction found. Check Edge Function logs.');
  }
}

// Run the checker
main().catch(console.error);
