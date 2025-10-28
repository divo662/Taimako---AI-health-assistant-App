-- =====================================================
-- CONVERSATIONAL CHAT SYSTEM SCHEMA
-- =====================================================
-- This creates tables for ChatGPT-style health conversations

-- 1. CONVERSATIONS TABLE (Chat Sessions)
CREATE TABLE IF NOT EXISTS conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL DEFAULT 'Health Chat',
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'archived')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Conversation metadata
    total_messages INTEGER DEFAULT 0,
    has_prediction BOOLEAN DEFAULT FALSE,
    prediction_id VARCHAR(100),
    
    -- Location context for the conversation
    state_code VARCHAR(10),
    lga_code VARCHAR(50),
    
    -- Indexes for performance
    CONSTRAINT conversations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- 2. MESSAGES TABLE (Individual Chat Messages)
CREATE TABLE IF NOT EXISTS messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Message content
    content TEXT NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    
    -- Message metadata
    message_type VARCHAR(30) DEFAULT 'text' CHECK (message_type IN ('text', 'prediction', 'follow_up', 'clarification')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- AI-specific fields
    tokens_used INTEGER DEFAULT 0,
    processing_time_ms INTEGER DEFAULT 0,
    
    -- Prediction data (if this message contains a prediction)
    prediction_data JSONB,
    confidence_score DECIMAL(3,2),
    urgency VARCHAR(20),
    severity VARCHAR(20),
    
    -- Follow-up questions
    follow_up_questions JSONB, -- Array of questions the AI wants to ask
    
    -- Message context (for AI memory)
    context_data JSONB, -- Previous symptoms, user responses, etc.
    
    -- Indexes
    CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    CONSTRAINT messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- 3. CONVERSATION_CONTEXT TABLE (AI Memory)
CREATE TABLE IF NOT EXISTS conversation_context (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    
    -- Context data
    extracted_symptoms TEXT[], -- Symptoms mentioned so far
    current_concerns TEXT[], -- User's main concerns
    medical_history TEXT[], -- Relevant medical history mentioned
    current_medications TEXT[], -- Medications mentioned
    
    -- AI state
    conversation_stage VARCHAR(30) DEFAULT 'initial' CHECK (conversation_stage IN (
        'initial', 'symptom_collection', 'clarification', 'prediction', 'follow_up', 'completed'
    )),
    
    -- Location and demographic context
    location_context JSONB,
    demographic_context JSONB,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT conversation_context_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Conversations indexes
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_status ON conversations(status);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON conversations(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at DESC);

-- Messages indexes
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_user_id ON messages(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_messages_role ON messages(role);
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(message_type);

-- Context indexes
CREATE INDEX IF NOT EXISTS idx_context_conversation_id ON conversation_context(conversation_id);
CREATE INDEX IF NOT EXISTS idx_context_stage ON conversation_context(conversation_stage);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_context ENABLE ROW LEVEL SECURITY;

-- Conversations policies
CREATE POLICY "Users can view their own conversations" ON conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own conversations" ON conversations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations" ON conversations
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations" ON conversations
    FOR DELETE USING (auth.uid() = user_id);

-- Messages policies
CREATE POLICY "Users can view messages in their conversations" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conversations 
            WHERE conversations.id = messages.conversation_id 
            AND conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert messages in their conversations" ON messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM conversations 
            WHERE conversations.id = messages.conversation_id 
            AND conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own messages" ON messages
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages" ON messages
    FOR DELETE USING (auth.uid() = user_id);

-- Context policies
CREATE POLICY "Users can view context of their conversations" ON conversation_context
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conversations 
            WHERE conversations.id = conversation_context.conversation_id 
            AND conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert context for their conversations" ON conversation_context
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM conversations 
            WHERE conversations.id = conversation_context.conversation_id 
            AND conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update context of their conversations" ON conversation_context
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM conversations 
            WHERE conversations.id = conversation_context.conversation_id 
            AND conversations.user_id = auth.uid()
        )
    );

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to create a new conversation
CREATE OR REPLACE FUNCTION create_conversation(
    p_user_id UUID,
    p_title VARCHAR(255) DEFAULT 'Health Chat',
    p_state_code VARCHAR(10) DEFAULT NULL,
    p_lga_code VARCHAR(50) DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    conversation_id UUID;
BEGIN
    INSERT INTO conversations (user_id, title, state_code, lga_code)
    VALUES (p_user_id, p_title, p_state_code, p_lga_code)
    RETURNING id INTO conversation_id;
    
    -- Initialize context
    INSERT INTO conversation_context (conversation_id, conversation_stage)
    VALUES (conversation_id, 'initial');
    
    RETURN conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add a message to conversation
CREATE OR REPLACE FUNCTION add_message(
    p_conversation_id UUID,
    p_user_id UUID,
    p_content TEXT,
    p_role VARCHAR(20),
    p_message_type VARCHAR(30) DEFAULT 'text',
    p_prediction_data JSONB DEFAULT NULL,
    p_follow_up_questions JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    message_id UUID;
BEGIN
    INSERT INTO messages (
        conversation_id, user_id, content, role, message_type,
        prediction_data, follow_up_questions
    )
    VALUES (
        p_conversation_id, p_user_id, p_content, p_role, p_message_type,
        p_prediction_data, p_follow_up_questions
    )
    RETURNING id INTO message_id;
    
    -- Update conversation stats
    UPDATE conversations 
    SET 
        total_messages = total_messages + 1,
        last_message_at = NOW(),
        updated_at = NOW(),
        has_prediction = CASE WHEN p_prediction_data IS NOT NULL THEN TRUE ELSE has_prediction END
    WHERE id = p_conversation_id;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get conversation with messages
CREATE OR REPLACE FUNCTION get_conversation_with_messages(p_conversation_id UUID)
RETURNS TABLE (
    conversation_id UUID,
    title VARCHAR(255),
    status VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    total_messages INTEGER,
    messages JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.title,
        c.status,
        c.created_at,
        c.total_messages,
        COALESCE(
            json_agg(
                json_build_object(
                    'id', m.id,
                    'content', m.content,
                    'role', m.role,
                    'message_type', m.message_type,
                    'timestamp', m.timestamp,
                    'prediction_data', m.prediction_data,
                    'follow_up_questions', m.follow_up_questions
                ) ORDER BY m.timestamp
            ) FILTER (WHERE m.id IS NOT NULL),
            '[]'::json
        ) as messages
    FROM conversations c
    LEFT JOIN messages m ON c.id = m.conversation_id
    WHERE c.id = p_conversation_id
    GROUP BY c.id, c.title, c.status, c.created_at, c.total_messages;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's recent conversations
CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id UUID, p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    title VARCHAR(255),
    status VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    last_message_at TIMESTAMP WITH TIME ZONE,
    total_messages INTEGER,
    has_prediction BOOLEAN,
    last_message_preview TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.title,
        c.status,
        c.created_at,
        c.last_message_at,
        c.total_messages,
        c.has_prediction,
        COALESCE(
            (SELECT m.content 
             FROM messages m 
             WHERE m.conversation_id = c.id 
             ORDER BY m.timestamp DESC 
             LIMIT 1),
            'No messages yet'
        ) as last_message_preview
    FROM conversations c
    WHERE c.user_id = p_user_id
    ORDER BY c.last_message_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SAMPLE DATA (Optional)
-- =====================================================

-- Insert sample conversation for testing
-- INSERT INTO conversations (user_id, title, state_code, lga_code) 
-- VALUES ('your-user-id', 'Headache and Cold Symptoms', 'LAG', 'Ikeja');

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE conversations IS 'Stores chat sessions/conversations between users and AI';
COMMENT ON TABLE messages IS 'Individual messages within conversations';
COMMENT ON TABLE conversation_context IS 'AI memory and context for ongoing conversations';

COMMENT ON COLUMN conversations.status IS 'active, completed, or archived';
COMMENT ON COLUMN messages.role IS 'user, assistant, or system';
COMMENT ON COLUMN messages.message_type IS 'text, prediction, follow_up, or clarification';
COMMENT ON COLUMN conversation_context.conversation_stage IS 'Current stage of the conversation';
