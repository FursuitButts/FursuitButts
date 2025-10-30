# frozen_string_literal: true

class PostAppeal < ApplicationRecord
  belongs_to_user(:creator, ip: true, counter_cache: "post_appealed_count", clones: :updater)
  belongs_to_user(:updater, ip: true)
  belongs_to(:post)

  validates(:reason, length: { maximum: 140 })
  validate(:validate_post_is_appealable, on: :create)
  validate(:validate_creator_is_not_limited, on: :create)
  validates(:creator, uniqueness: { scope: :post, message: "has already appealed this post" }, on: :create)
  after_create(:prune_disapprovals)
  after_create(:create_post_event)
  after_commit(:update_post)

  enum(:status, {
    pending:  0,
    accepted: 1,
    rejected: 2,
  })

  scope(:expired, -> { pending.where(post_appeals: { created_at: ...PostPruner::MODERATION_WINDOW.days.ago }) })

  def prune_disapprovals
    PostDisapproval.where(post: post).delete_all
  end

  def update_post
    post.update!(is_appealed: post.appeals.pending.exists?, updater: updater)
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

  def accept!(approver)
    update!(status: :accepted, updater: approver)
    PostEvent.add!(post_id, approver, :appeal_accepted, post_appeal_id: id)
    creator.notify_for_upload(self, :appeal_accept) if creator_id != approver.id
  end

  def reject!(rejector)
    update!(status: :rejected, updater: rejector)
    PostEvent.add!(post_id, rejector, :appeal_rejected, post_appeal_id: id)
    creator.notify_for_upload(self, :appeal_reject) if creator_id != rejector.id
  end

  module SearchMethods
    def post_tags_match(query, user)
      where(post_id: Post.tag_match_sql(query, user))
    end

    def query_dsl
      super
        .field(:reason_matches, :reason)
        .field(:status)
        .field(:post_id)
        .field(:ip_addr, :creator_ip_addr)
        .field(:updater_ip_addr)
        .custom(:post_tags_match, ->(q, v, user) { q.post_tags_match(v, user) })
        .association(:creator)
        .association(:updater)
        .association(:post)
    end
  end

  extend(SearchMethods)

  def self.available_includes
    %i[creator post]
  end
end
