SELECT id,
       artist_id,
       name,
       updater_id,
       created_at,
       updated_at,
       other_names,
       urls,
       notes_changed
FROM public.artist_versions ORDER BY id
