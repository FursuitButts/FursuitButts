SELECT artist_versions.id,
       artist_versions.artist_id,
       artist_versions.name,
       artist_versions.updater_id,
       artist_versions.created_at,
       artist_versions.updated_at,
       artist_versions.other_names,
       artist_versions.urls,
       artist_versions.notes_changed
FROM public.artist_versions ORDER BY artist_versions.id ASC
