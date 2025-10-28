# Taimako - Your AI Health Companion 🏥

Taimako is an AI-powered health assistance mobile application built for the Hedera Africa Hackathon 2025. The app uses conversational AI, location-specific health insights, and blockchain-verified medical predictions to provide accessible healthcare guidance for users across Nigeria.

## 🎯 Key Features

### AI-Powered Health Assistant
- **Conversational AI**: Chat with an intelligent health assistant using Groq's Llama 3.3 model
- **Symptom Analysis**: Describe your symptoms naturally and receive AI-powered health insights
- **Context-Aware**: Remembers previous conversations and adapts responses based on your health profile
- **Follow-up Questions**: Intelligent follow-up questions to better understand your condition

### Location-Specific Insights
- **State & LGA Integration**: Get health advice specific to your location (all 36 Nigerian states + 774 LGAs)
- **Local Disease Awareness**: Information about regional health concerns and common illnesses
- **Emergency Services**: Quick access to nearby emergency services based on your location

### Blockchain Verification
- **Hedera Integration**: All health predictions are logged on the Hedera Consensus Service (HCS)
- **Immutable Records**: Transparent, verifiable health prediction history
- **User Privacy**: Sensitive data is hashed before blockchain storage
- **Transaction Verification**: View your predictions on Hashscan explorer

### Smart Health Predictions
- **Nigerian Medical Dataset**: Trained on local health conditions (Malaria, Typhoid, Lassa Fever, etc.)
- **AI Feedback System**: Like/dislike buttons to improve AI accuracy
- **Confidence Scoring**: Understand prediction reliability with confidence percentages
- **Urgency Assessment**: Automatic classification of medical urgency (low/moderate/high/critical)

### User Experience
- **Profile Management**: Store your basic health information and preferences
- **Conversation History**: Access past health conversations
- **Pull-to-Refresh**: Easy data synchronization
- **Beautiful UI**: Modern, clean interface with brand colors (#00D4AA)
- **Offline Support**: Works with limited connectivity

## 🏆 Hackathon Track

**Track 4: AI & DePIN**
- AI-powered health predictions using Groq
- Blockchain-backed immutable medical records
- Location-aware health services (DePIN principles)

## 🚀 Tech Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language
- **Provider**: State management
- **Supabase Flutter**: Authentication & database
- **ScreenUtil**: Responsive UI design

### Backend & AI
- **Supabase**: Backend as a Service (PostgreSQL, Edge Functions, Auth)
- **Groq AI**: LLM inference with Llama 3.3
- **Supabase Edge Functions**: Serverless compute for AI processing

### Blockchain
- **Hedera Hashgraph**: Public DLT network
- **HCS (Hedera Consensus Service)**: Immutable message logging
- **Hashgraph SDK**: TypeScript SDK for Hedera transactions

### Database
- **PostgreSQL**: Primary database via Supabase
- **Row Level Security (RLS)**: User data privacy
- **Real-time subscriptions**: Live data updates

## 📋 Prerequisites

- Flutter SDK (>=3.24.0)
- Android Studio / Xcode
- Node.js (for Edge Functions)
- Supabase account
- Hedera account (testnet credentials)

## 🔧 Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/taimako.git
cd taimako
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Set up environment variables**
Create a `.env` file in the root directory:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
GROQ_API_KEY=your_groq_api_key
HEDERA_ACCOUNT_ID=your_hedera_account_id
HEDERA_PRIVATE_KEY=your_hedera_private_key
HEDERA_TOPIC_ID=your_topic_id
HEDERA_NETWORK=testnet
```

4. **Run database migrations**
Execute the SQL scripts in your Supabase SQL Editor:
- `conversational_chat_schema.sql`
- `add_feedback_to_messages.sql`
- `fix_get_conversation_function.sql`

5. **Deploy Edge Functions**
Use the Supabase CLI to deploy Edge Functions:
```bash
supabase functions deploy conversational_ai_edge_function
supabase functions deploy log-to-hedera
supabase functions deploy predict-illness-upgraded
```

6. **Run the app**
```bash
flutter run
```

## 📱 APK Installation

To build an APK for Android:

```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## 🏗️ Project Structure

```
taimako/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── screens/
│   │   ├── auth/                    # Login & Registration
│   │   ├── onboarding/              # User onboarding
│   │   ├── main/
│   │   │   ├── home_screen.dart     # Main chat interface
│   │   │   ├── history_screen.dart  # Conversation history
│   │   │   └── profile_screen.dart  # User profile
│   │   └── splash_screen.dart
│   ├── services/
│   │   ├── supabase_service.dart    # Database operations
│   │   ├── hedera_service.dart      # Blockchain logging
│   │   ├── health_prediction_service.dart
│   │   └── ...
│   └── theme/
│       └── app_theme.dart
├── assets/
│   ├── images/                      # App logos & images
│   └── icons/
├── android/                         # Android native code
├── ios/                            # iOS native code
├── conversational_ai_edge_function.ts    # AI chat Edge Function
├── log-to-hedera.ts                # Hedera logging Edge Function
└── supabase_setup.md               # Database setup guide
```

## 🔐 Security & Privacy

- **Row Level Security**: Users can only access their own data
- **Hedera Hashing**: Sensitive PII is hashed before blockchain storage
- **Encrypted Storage**: Supabase handles encryption at rest
- **No Data Mining**: Your health data is private and secure

## 📊 Database Schema

### Main Tables
- `user_profiles`: User demographic and health information
- `conversations`: Chat sessions between users and AI
- `messages`: Individual messages within conversations
- `predictions`: Health predictions with Hedera transaction IDs
- `hedera_logs`: Blockchain transaction logs
- `conversation_context`: AI memory and context

## 🤖 How AI Works

1. User describes symptoms in natural language
2. AI extracts symptoms and applies Nigerian medical dataset
3. Context-aware analysis considers location, age, gender
4. Confidence scoring and urgency assessment
5. Prediction logged to Hedera blockchain for verification
6. User feedback improves future predictions

## 🌐 Nigerian Health Coverage

- **36 States**: Full coverage of all Nigerian states
- **774 LGAs**: Complete Local Government Area support
- **Regional Illnesses**: Malaria, Typhoid, Lassa Fever, Cholera, etc.
- **Cultural Awareness**: Culturally sensitive health advice

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📝 License

This project is created for the Hedera Africa Hackathon 2025.

## 👥 Team

- Divinity
- AI-Powered Health Predictions
- Blockchain Verification

## 🙏 Acknowledgments

- **Hedera Hashgraph**: For the public distributed ledger
- **Supabase**: For backend infrastructure
- **Groq**: For fast AI inference
- **Flutter Community**: For excellent documentation

## 📞 Support

For issues, feature requests, or questions:
- GitHub Issues: [Create an issue](https://github.com/yourusername/taimako/issues)
- Email: support@taimako.ng

## 🎉 Hackathon Submission

**Project for**: Hedera Africa Hackathon 2025  
**Track**: AI & DePIN  
**Goal**: Top 3 positions  
**Impact**: Accessible healthcare for 200 million+ Nigerians

---

Built with ❤️ for African healthcare accessibility
