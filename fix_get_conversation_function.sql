-- =====================================================
-- FIX get_conversation_with_messages FUNCTION
-- =====================================================
-- This fixes the "structure of query does not match function result type" error

CREATE OR REPLACE FUNCTION get_conversation_with_messages(p_conversation_id UUID)
RETURNS TABLE (
    conversation_id UUID,
    title VARCHAR(255),
    status VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    total_messages INTEGER,
    messages JSONB
) AS $$
DECLARE
    result_record RECORD;
BEGIN
    -- Return a single row for the conversation
    RETURN QUERY
    SELECT 
        c.id as conversation_id,
        c.title as title,
        c.status as status,
        c.created_at as created_at,
        c.total_messages as total_messages,
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
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
                )
                FROM messages m
                WHERE m.conversation_id = c.id
            ),
            '[]'::jsonb
        ) as messages
    FROM conversations c
    WHERE c.id = p_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

