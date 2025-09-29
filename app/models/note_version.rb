# frozen_string_literal: true

class NoteVersion < ApplicationRecord
  belongs_to_user(:updater, ip: true, counter_cache: "note_update_count")
  belongs_to(:note)

  module SearchMethods
    def query_dsl
      super
        .field(:post_id)
        .field(:note_id)
        .field(:is_active)
        .field(:body_matches, :body)
        .field(:ip_addr, :updater_ip_addr)
        .association(:updater)
        .association(:note)
        .association(note: :post)
    end
  end

  extend(SearchMethods)

  def previous
    NoteVersion.where(note_id: note_id).where.lt(updated_at: updated_at).order(updated_at: :desc).first
  end

  def self.available_includes
    %i[note updater]
  end
end
