SELECT id,
       name,
       post_count,
       category,
       related_tags,
       related_tags_updated_at,
       created_at,
       updated_at,
       is_locked
FROM public.tags ORDER BY id
