SELECT id,
       creator_id,
       forum_topic_id,
       script,
       status,
       created_at,
       updated_at,
       approver_id,
       forum_post_id,
       title
FROM public.bulk_update_requests ORDER BY id
