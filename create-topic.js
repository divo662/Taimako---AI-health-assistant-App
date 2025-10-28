const {
  Client,
  TopicCreateTransaction,
  AccountId,
  PrivateKey,
} = require("@hashgraph/sdk");

async function createTopic() {
  // Your Hedera credentials
  const accountId = "0.0.7096886";
  const privateKey = "0xac343b146023f324792a04c317db6d0e3d9c422cbd0f0b1c1e5257f196f5067d";

  // Create testnet client
  const client = Client.forTestnet();
  
  // Set operator with ECDSA private key
  client.setOperator(
    AccountId.fromString(accountId),
    PrivateKey.fromStringECDSA(privateKey)
  );

  console.log("🔗 Creating Hedera HCS Topic...");

  // Create topic
  const transaction = new TopicCreateTransaction()
    .setTopicMemo("Taimako Health Predictions - AI Medical Assistant")
    .setAdminKey(PrivateKey.fromStringECDSA(privateKey).publicKey);

  // Execute transaction
  const txResponse = await transaction.execute(client);
  
  // Get receipt
  const receipt = await txResponse.getReceipt(client);
  
  // Get topic ID
  const topicId = receipt.topicId.toString();

  console.log("✅ Topic created successfully!");
  console.log("📝 Topic ID:", topicId);
  console.log("🔗 Explorer:", `https://hashscan.io/testnet/topic/${topicId}`);
  console.log("\n📋 Add this to your .env file:");
  console.log(`HEDERA_TOPIC_ID=${topicId}`);

  client.close();
}

createTopic().catch(console.error);
