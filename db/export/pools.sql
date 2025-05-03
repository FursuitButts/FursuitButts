SELECT pools.id,
       pools.name,
       pools.creator_id,
       pools.description,
       pools.is_active,
       pools.post_ids,
       pools.created_at,
       pools.updated_at,
       pools.artist_names
FROM public.pools ORDER BY pools.id ASC
