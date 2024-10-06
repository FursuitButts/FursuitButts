SELECT id,
       name,
       creator_id,
       description,
       is_active,
       post_ids,
       created_at,
       updated_at,
       artist_names
FROM public.pools ORDER BY id
