SELECT id,
       name,
       creator_id,
       created_at,
       updated_at,
       other_names,
       linked_user_id,
       is_locked
FROM public.artists ORDER BY id
