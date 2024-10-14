# frozen_string_literal: true

class PostEvent < ApplicationRecord
  belongs_to :creator, class_name: "User"
  belongs_to :post
  enum :action, {
    deleted:                 0,
    undeleted:               1,
    approved:                2,
    unapproved:              3,
    flag_created:            4,
    flag_removed:            5,
    favorites_moved:         6,
    favorites_received:      7,
    rating_locked:           8,
    rating_unlocked:         9,
    status_locked:           10,
    status_unlocked:         11,
    note_locked:             12,
    note_unlocked:           13,
    replacement_accepted:    14,
    replacement_rejected:    15,
    replacement_promoted:    20,
    replacement_deleted:     16,
    expunged:                17,
    comment_disabled:        18,
    comment_enabled:         19,
    comment_locked:          21,
    comment_unlocked:        22,
    changed_bg_color:        23,
    changed_thumbnail_frame: 24,
    appeal_created:          25,
    appeal_accepted:         26,
    appeal_rejected:         27,
    copied_notes:            28,
  }

  MOD_ONLY_SEARCH_ACTIONS = [
    actions[:comment_disabled],
    actions[:comment_enabled],
    actions[:comment_locked],
    actions[:comment_unlocked],
  ].freeze

  def self.search_options_for(user)
    options = actions.keys
    return options if user.is_moderator?
    options.reject { |action| MOD_ONLY_SEARCH_ACTIONS.any?(actions[action]) }
  end

  def self.add(post_id, creator, action, data = {})
    create!(post_id: post_id, creator: creator, action: action.to_s, extra_data: data)
  end

  def is_creator_visible?(user)
    case action
    when "flag_created"
      user.can_view_flagger?(creator_id)
    else
      true
    end
  end

  module SearchMethods
    def search(params)
      q = super

      if params[:post_id].present?
        q = q.where(post_id: params[:post_id])
      end

      q = q.where_user(:creator_id, :creator, params) do |condition, user_ids|
        condition.where.not(
          action:     actions[:flag_created],
          creator_id: user_ids.reject { |user_id| CurrentUser.can_view_flagger?(user_id) },
        )
      end

      if params[:action].present?
        if !CurrentUser.is_moderator? && MOD_ONLY_SEARCH_ACTIONS.include?(actions[params[:action]])
          raise(User::PrivilegeError)
        end
        q = q.where(action: actions[params[:action]])
      end

      q.apply_basic_order(params)
    end
  end

  module ApiMethods
    # whitelisted data attributes
    def allowed_data
      %w[reason parent_id child_id bg_color replacement_id old_md5 new_md5 source_post_id md5 note_count]
    end

    def serializable_hash(*)
      hash = super.merge(**extra_data.slice(*allowed_data))
      hash[:creator_id] = nil unless is_creator_visible?(CurrentUser.user)
      hash
    end
  end

  include ApiMethods
  extend SearchMethods

  def self.available_includes
    %i[post]
  end
end
