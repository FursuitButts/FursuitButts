#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment"))

Note.where("body LIKE '%from post #%'").where(x: 0, y: 0, width: 0, height: 0, is_active: false).find_each do |note|
  if note.body =~ /Copied (\d+) notes? from post #(\d+)/
    count = $1.to_i
    post_id = $2.to_i
    CurrentUser.scoped(note.creator, note.versions.first.updater_ip_addr) do
      PostEvent.create!(
        post_id:    note.post_id,
        creator:    note.creator,
        action:     "copied_notes",
        extra_data: { source_post_id: post_id, note_count: count },
        created_at: note.created_at,
      )
      note.destroy
    end
  end
end
