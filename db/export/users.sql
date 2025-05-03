
WITH feedback_counts AS (
  SELECT
    user_feedbacks.user_id,
    COUNT(*) FILTER (WHERE user_feedbacks.category = 'positive' AND user_feedbacks.is_deleted = false) AS positive,
    COUNT(*) FILTER (WHERE user_feedbacks.category = 'neutral' AND user_feedbacks.is_deleted = false) AS neutral,
    COUNT(*) FILTER (WHERE user_feedbacks.category = 'negative' AND user_feedbacks.is_deleted = false) AS negative
  FROM public.user_feedbacks
  WHERE user_feedbacks.is_deleted = false
  GROUP BY user_feedbacks.user_id
)
SELECT users.id,
       users.created_at,
       users.name,
       users.level,
       users.wiki_update_count as wiki_page_version_count,
       users.artist_update_count as artist_version_count,
       users.pool_update_count as pool_version_count,
       users.forum_post_count,
       users.comment_count,
       users.favorite_count,
       COALESCE(feedback_counts.positive, 0) as positive_feedback_count,
       COALESCE(feedback_counts.neutral, 0) as neutral_feedback_count,
       COALESCE(feedback_counts.negative, 0) as negative_feedback_count,
       users.profile_about,
       users.profile_artinfo,
       users.base_upload_limit,
       users.post_count as post_upload_count,
       users.post_update_count,
       users.note_update_count,
       users.avatar_id,
       (users.bit_prefs::bit(64) & (1 << 8)::bit(64) = (1 << 8)::bit(64)) as can_approve_posts,
       (users.bit_prefs::bit(64) & (1 << 9)::bit(64) = (1 << 9)::bit(64)) as unrestricted_uploads,
       (users.bit_prefs::bit(64) & (1 << 14)::bit(64) = (1 << 14)::bit(64)) as disable_user_dmails,
       (users.bit_prefs::bit(64) & (1 << 22)::bit(64) = (1 << 22)::bit(64)) as can_manage_aibur
FROM public.users
LEFT JOIN feedback_counts ON feedback_counts.user_id = users.id
ORDER BY users.id ASC

