# frozen_string_literal: true

class NoteVersion < ApplicationRecord
  belongs_to_user(:updater, ip: true, counter_cache: "note_update_count")
  belongs_to(:note)
  scope(:for_user, ->(user_id) { where("updater_id = ?", user_id) })

  def self.search(params, user)
    q = super

    q = q.where_user(:updater_id, :updater, params)

    if params[:post_id]
      q = q.where(post_id: params[:post_id].split(",").map(&:to_i))
    end

    if params[:note_id]
      q = q.where(note_id: params[:note_id].split(",").map(&:to_i))
    end

    q = q.attribute_matches(:is_active, params[:is_active])
    q = q.attribute_matches(:body, params[:body_matches])

    if params[:ip_addr].present?
      q = q.where("updater_ip_addr <<= ?", params[:ip_addr])
    end

    q.apply_basic_order(params)
  end

  def previous
    NoteVersion.where("note_id = ? and updated_at < ?", note_id, updated_at).order("updated_at desc").first
  end

  def self.available_includes
    %i[note updater]
  end
end
