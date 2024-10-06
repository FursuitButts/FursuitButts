SELECT id,
       wiki_page_id,
       updater_id,
       title,
       body,
       protection_level,
       created_at,
       updated_at,
       reason,
       parent
FROM public.wiki_page_versions ORDER BY id
