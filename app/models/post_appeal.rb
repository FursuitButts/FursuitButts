# frozen_string_literal: true

class PostAppeal < ApplicationRecord
  belongs_to_creator(counter_cache: "post_appealed_count")
  belongs_to(:post)

  validates(:reason, length: { maximum: 140 })
  validate(:validate_post_is_appealable, on: :create)
  validate(:validate_creator_is_not_limited, on: :create)
  validates(:creator, uniqueness: { scope: :post, message: "has already appealed this post" }, on: :create)
  after_create(:prune_disapprovals)
  after_create(:create_post_event)

  enum(:status, {
    pending:  0,
    accepted: 1,
    rejected: 2,
  })

  scope(:expired, -> { pending.where("post_appeals.created_at < ?", PostPruner::MODERATION_WINDOW.days.ago) })
  scope(:for_user, ->(user_id) { where(creator_id: user_id) })

  def prune_disapprovals
    PostDisapproval.where(post: post).delete_all
  end

  def create_post_event
    PostEvent.add!(post_id, creator, :appeal_created, post_appeal_id: id)
  end

  def validate_creator_is_not_limited
    allowed = creator.can_post_appeal_with_reason
    if allowed != true
      errors.add(:creator, User.throttle_reason(allowed))
      false
    end
  end

  def validate_post_is_appealable
    errors.add(:post, "cannot be appealed") unless post.is_appealable?
  end

  def accept!
    update!(status: :accepted)
    PostEvent.add!(post_id, CurrentUser.user, :appeal_accepted, post_appeal_id: id)
    creator.notify_for_upload(self, :appeal_accept) if creator_id != CurrentUser.id
  end

  def reject!
    update!(status: :rejected)
    PostEvent.add!(post_id, CurrentUser.user, :appeal_rejected, post_appeal_id: id)
    creator.notify_for_upload(self, :appeal_reject) if creator_id != CurrentUser.id
  end

  module SearchMethods
    def post_tags_match(query)
      where(post_id: Post.tag_match_sql(query))
    end

    def search(params)
      q = super
      q = q.attribute_matches(:reason, params[:reason_matches])
      q = q.where(status: params[:status]) if params[:status].present?
      q = q.where_user(:creator_id, :creator, params)

      if params[:post_id].present?
        q = q.where(post_id: params[:post_id].split(",").map(&:to_i))
      end

      if params[:post_tags_match].present?
        q = q.post_tags_match(params[:post_tags_match])
      end

      if params[:ip_addr].present?
        q = q.where("creator_ip_addr <<= ?", params[:ip_addr])
      end

      q.apply_basic_order(params)
    end
  end

  extend(SearchMethods)

  def self.available_includes
    %i[creator post]
  end
end
