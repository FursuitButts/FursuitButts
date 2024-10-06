SELECT id,
       created_at,
       updated_at,
       category,
       is_locked,
       tag_id,
       updater_id,
       reason
FROM public.tag_versions ORDER BY id
