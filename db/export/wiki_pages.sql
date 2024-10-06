SELECT id,
       creator_id,
       title,
       body,
       protection_level,
       created_at,
       updated_at,
       updater_id,
       parent
FROM public.wiki_pages ORDER BY id
