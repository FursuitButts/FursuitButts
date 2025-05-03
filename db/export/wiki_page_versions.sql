SELECT wiki_page_versions.id,
       wiki_page_versions.wiki_page_id,
       wiki_page_versions.updater_id,
       wiki_page_versions.title,
       wiki_page_versions.body,
       wiki_page_versions.protection_level,
       wiki_page_versions.created_at,
       wiki_page_versions.updated_at,
       wiki_page_versions.reason,
       wiki_page_versions.parent
FROM public.wiki_page_versions ORDER BY wiki_page_versions.id ASC
