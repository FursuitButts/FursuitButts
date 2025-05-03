SELECT tag_implications.id,
       tag_implications.antecedent_name,
       tag_implications.consequent_name,
       tag_implications.creator_id,
       tag_implications.forum_topic_id,
       tag_implications.status,
       tag_implications.created_at,
       tag_implications.updated_at,
       tag_implications.approver_id,
       tag_implications.forum_post_id,
       tag_implications.descendant_names,
       tag_implications.reason
FROM public.tag_implications ORDER BY tag_implications.id ASC
