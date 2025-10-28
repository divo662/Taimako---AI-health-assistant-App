// =====================================================
// TAIMAKO EDGE FUNCTION: log-to-hedera
// =====================================================
// This function logs prediction data to Hedera Consensus Service (HCS)
// for immutable, transparent health record verification

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  Client,
  TopicMessageSubmitTransaction,
  TopicId,
  AccountId,
  PrivateKey,
} from "npm:@hashgraph/sdk@^2.40.0";

// Hedera Configuration
const HEDERA_ACCOUNT_ID = Deno.env.get("HEDERA_ACCOUNT_ID");
const HEDERA_PRIVATE_KEY = Deno.env.get("HEDERA_PRIVATE_KEY");
const HEDERA_TOPIC_ID = Deno.env.get("HEDERA_TOPIC_ID"); // Your HCS Topic ID
const HEDERA_NETWORK = Deno.env.get("HEDERA_NETWORK") || "testnet"; // testnet or mainnet

// Supabase Configuration
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface HederaLogRequest {
  prediction_id: string;
  user_id: string;
  prediction_data: {
    illness: string;
    confidence: number;
    urgency: string;
    severity: string;
  };
}

serve(async (req) => {
  // CORS Headers
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("🔗 Starting Hedera logging...");

    // Parse request
    const { prediction_id, user_id, prediction_data }: HederaLogRequest = await req.json();

    if (!prediction_id || !user_id || !prediction_data) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify Hedera credentials
    if (!HEDERA_ACCOUNT_ID || !HEDERA_PRIVATE_KEY || !HEDERA_TOPIC_ID) {
      console.error("❌ Missing Hedera configuration");
      return new Response(
        JSON.stringify({ error: "Hedera not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Step 1: Hash sensitive data for privacy
    const userIdHash = await hashData(user_id);
    const symptomsHash = await hashData(JSON.stringify(prediction_data));

    // Step 2: Create blockchain payload (NO PII)
    const blockchainPayload = {
      prediction_id,
      user_id_hash: userIdHash,
      illness: prediction_data.illness,
      confidence: prediction_data.confidence,
      urgency: prediction_data.urgency,
      severity: prediction_data.severity,
      timestamp: new Date().toISOString(),
      data_hash: symptomsHash,
      app: "Taimako",
      version: "1.0.0",
    };

    console.log("📦 Blockchain payload prepared:", {
      prediction_id,
      illness: prediction_data.illness,
      timestamp: blockchainPayload.timestamp,
    });

    // Step 3: Submit to Hedera Consensus Service
    const transactionId = await submitToHedera(blockchainPayload);

    console.log(`✅ Hedera transaction successful: ${transactionId}`);

    // Step 4: Save to hedera_logs table
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data, error } = await supabase
      .from("hedera_logs")
      .insert({
        user_id,
        prediction_id,
        hedera_transaction_id: transactionId,
        log_data: blockchainPayload,
        verification_status: "confirmed",
      })
      .select()
      .single();

    if (error) {
      console.error("❌ Error saving to hedera_logs:", error);
      throw new Error(`Database error: ${error.message}`);
    }

    console.log("💾 Hedera log saved to database");

    // Step 5: Update prediction with Hedera transaction ID
    await supabase
      .from("predictions")
      .update({ hedera_transaction_id: transactionId })
      .eq("prediction_id", prediction_id);

    return new Response(
      JSON.stringify({
        success: true,
        hedera_transaction_id: transactionId,
        message: "Successfully logged to Hedera blockchain",
        explorer_url: getExplorerUrl(transactionId),
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("❌ Error in log-to-hedera:", error);
    return new Response(
      JSON.stringify({
        error: error.message || "Failed to log to Hedera",
        details: error.toString(),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

// =====================================================
// SUBMIT TO HEDERA CONSENSUS SERVICE
// =====================================================
async function submitToHedera(payload: any): Promise<string> {
  try {
    console.log("🔗 Connecting to Hedera network...");

    // Initialize Hedera client
    let client: Client;

    if (HEDERA_NETWORK === "mainnet") {
      client = Client.forMainnet();
    } else {
      client = Client.forTestnet();
    }

    // Set operator with your account credentials
    client.setOperator(
      AccountId.fromString(HEDERA_ACCOUNT_ID!),
      PrivateKey.fromStringECDSA(HEDERA_PRIVATE_KEY!) // ECDSA for hex keys
    );

    console.log(`✅ Connected to Hedera ${HEDERA_NETWORK}`);
    console.log(`📍 Account: ${HEDERA_ACCOUNT_ID}`);
    console.log(`📝 Topic: ${HEDERA_TOPIC_ID}`);

    // Create topic message transaction
    const transaction = new TopicMessageSubmitTransaction()
      .setTopicId(TopicId.fromString(HEDERA_TOPIC_ID!))
      .setMessage(JSON.stringify(payload));

    // Execute transaction
    console.log("📤 Submitting message to HCS...");
    const txResponse = await transaction.execute(client);

    // Get receipt
    const receipt = await txResponse.getReceipt(client);

    // Get transaction ID
    const transactionId = txResponse.transactionId.toString();

    console.log(`🔗 Hedera transaction ID: ${transactionId}`);
    console.log(`📋 Status: ${receipt.status.toString()}`);

    // Close client
    client.close();

    return transactionId;
  } catch (error) {
    console.error("❌ Hedera submission error:", error);
    throw new Error(`Hedera error: ${error.message}`);
  }
}

// =====================================================
// HASH DATA FOR PRIVACY (Using Web Crypto API)
// =====================================================
async function hashData(data: string): Promise<string> {
  const encoder = new TextEncoder();
  const dataBuffer = encoder.encode(data);
  const hashBuffer = await crypto.subtle.digest("SHA-256", dataBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
  return hashHex;
}

// =====================================================
// GET HEDERA EXPLORER URL
// =====================================================
function getExplorerUrl(transactionId: string): string {
  const network = HEDERA_NETWORK === "mainnet" ? "" : "testnet.";
  return `https://${network}hashscan.io/transaction/${transactionId}`;
}
