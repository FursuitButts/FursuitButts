# frozen_string_literal: true

class MediaAssetPolicy < ApplicationPolicy
  def index?
    member?
  end

  def append?
    member? && creator?
  end

  def finalize?
    member? && creator?
  end

  def cancel?
    member? && creator?
  end

  def creator?
    !record.is_a?(MediaAsset) || record.creator_id == user.id
  end

  def permitted_search_params
    super + %i[checksum md5 file_ext pixel_hash status status_message_matches creator_id creator_name]
  end

  def api_attributes
    super - %i[media_metadata_id checksum last_chunk_id]
  end

  def visible_for_search(relation)
    q = super
    return q if user.is_staff?
    q.for_creator(user)
  end
end
