SELECT id,
       creator_id,
       post_id,
       x,
       y,
       width,
       height,
       body,
       created_at,
       updated_at,
       version
FROM public.notes ORDER BY id
