SELECT id,
       antecedent_name,
       consequent_name,
       creator_id,
       forum_topic_id,
       status,
       created_at,
       updated_at,
       post_count,
       approver_id,
       forum_post_id,
       reason
FROM public.tag_aliases ORDER BY id
