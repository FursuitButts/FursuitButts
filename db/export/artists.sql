SELECT artists.id,
       artists.name,
       artists.creator_id,
       artists.created_at,
       artists.updated_at,
       artists.other_names,
       artists.linked_user_id,
       artists.is_locked
FROM public.artists ORDER BY artists.id ASC
