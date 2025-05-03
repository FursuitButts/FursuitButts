SELECT bulk_update_requests.id,
       bulk_update_requests.creator_id,
       bulk_update_requests.forum_topic_id,
       bulk_update_requests.script,
       bulk_update_requests.status,
       bulk_update_requests.created_at,
       bulk_update_requests.updated_at,
       bulk_update_requests.approver_id,
       bulk_update_requests.forum_post_id,
       bulk_update_requests.title
FROM public.bulk_update_requests ORDER BY bulk_update_requests.id ASC
