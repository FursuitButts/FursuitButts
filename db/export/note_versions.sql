SELECT id,
       note_id,
       post_id,
       updater_id,
       x,
       y,
       width,
       height,
       is_active,
       body,
       created_at,
       updated_at,
       version
FROM public.note_versions ORDER BY id
