SELECT note_versions.id,
       note_versions.note_id,
       note_versions.post_id,
       note_versions.updater_id,
       note_versions.x,
       note_versions.y,
       note_versions.width,
       note_versions.height,
       note_versions.is_active,
       note_versions.body,
       note_versions.created_at,
       note_versions.updated_at,
       note_versions.version
FROM public.note_versions ORDER BY note_versions.id ASC
