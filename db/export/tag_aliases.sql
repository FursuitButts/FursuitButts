SELECT tag_aliases.id,
       tag_aliases.antecedent_name,
       tag_aliases.consequent_name,
       tag_aliases.creator_id,
       tag_aliases.forum_topic_id,
       tag_aliases.status,
       tag_aliases.created_at,
       tag_aliases.updated_at,
       tag_aliases.post_count,
       tag_aliases.approver_id,
       tag_aliases.forum_post_id,
       tag_aliases.reason
FROM public.tag_aliases ORDER BY tag_aliases.id ASC
