-- =====================================================
-- ADD FEEDBACK COLUMNS TO MESSAGES TABLE
-- =====================================================

-- Add like/dislike columns to messages table
ALTER TABLE messages ADD COLUMN IF NOT EXISTS user_feedback VARCHAR(10);
ALTER TABLE messages ADD COLUMN IF NOT EXISTS feedback_timestamp TIMESTAMP WITH TIME ZONE;

-- Add comment column for additional feedback
ALTER TABLE messages ADD COLUMN IF NOT EXISTS feedback_comment TEXT;

-- Create index for faster feedback queries
CREATE INDEX IF NOT EXISTS idx_messages_feedback ON messages(conversation_id, user_feedback) WHERE user_feedback IS NOT NULL;

-- Create updated function to handle feedback
CREATE OR REPLACE FUNCTION add_message_feedback(
    p_message_id UUID,
    p_user_id UUID,
    p_feedback VARCHAR(10), -- 'like' or 'dislike'
    p_comment TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
    -- Verify message belongs to user's conversation
    IF EXISTS (
        SELECT 1 FROM messages m
        JOIN conversations c ON m.conversation_id = c.id
        WHERE m.id = p_message_id AND c.user_id = p_user_id
    ) THEN
        -- Update message with feedback
        UPDATE messages
        SET 
            user_feedback = p_feedback,
            feedback_timestamp = NOW(),
            feedback_comment = COALESCE(p_comment, feedback_comment)
        WHERE id = p_message_id;
        
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get feedback statistics for a conversation
CREATE OR REPLACE FUNCTION get_conversation_feedback_stats(p_conversation_id UUID)
RETURNS TABLE (
    total_messages INTEGER,
    liked_messages INTEGER,
    disliked_messages INTEGER,
    no_feedback_messages INTEGER,
    like_percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_messages,
        COUNT(*) FILTER (WHERE user_feedback = 'like')::INTEGER as liked_messages,
        COUNT(*) FILTER (WHERE user_feedback = 'dislike')::INTEGER as disliked_messages,
        COUNT(*) FILTER (WHERE user_feedback IS NULL)::INTEGER as no_feedback_messages,
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE user_feedback = 'like') / 
            NULLIF(COUNT(*), 0), 
            2
        ) as like_percentage
    FROM messages
    WHERE conversation_id = p_conversation_id AND role = 'assistant';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all user feedback for analytics
CREATE OR REPLACE FUNCTION get_user_feedback_history(p_user_id UUID, p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    message_id UUID,
    conversation_id UUID,
    content_preview TEXT,
    feedback VARCHAR(10),
    feedback_timestamp TIMESTAMP WITH TIME ZONE,
    feedback_comment TEXT,
    message_type VARCHAR(30)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.conversation_id,
        LEFT(m.content, 100) as content_preview,
        m.user_feedback as feedback,
        m.feedback_timestamp,
        m.feedback_comment,
        m.message_type
    FROM messages m
    JOIN conversations c ON m.conversation_id = c.id
    WHERE c.user_id = p_user_id 
        AND m.role = 'assistant' 
        AND m.user_feedback IS NOT NULL
    ORDER BY m.feedback_timestamp DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update get_conversation_with_messages to include feedback
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
                    'follow_up_questions', m.follow_up_questions,
                    'user_feedback', m.user_feedback,
                    'feedback_timestamp', m.feedback_timestamp,
                    'feedback_comment', m.feedback_comment
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

-- Add comment for documentation
COMMENT ON COLUMN messages.user_feedback IS 'User feedback: like or dislike';
COMMENT ON COLUMN messages.feedback_timestamp IS 'When feedback was provided';
COMMENT ON COLUMN messages.feedback_comment IS 'Optional comment with feedback';
