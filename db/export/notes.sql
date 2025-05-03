SELECT notes.id,
       notes.creator_id,
       notes.post_id,
       notes.x,
       notes.y,
       notes.width,
       notes.height,
       notes.body,
       notes.created_at,
       notes.updated_at,
       notes.version
FROM public.notes ORDER BY notes.id ASC
