# frozen_string_literal: true

class PostApproval < ApplicationRecord
  belongs_to_user(:user, ip: true) # TODO: convert to creator
  belongs_to(:post, inverse_of: :approvals)

  validate(:validate_approval)

  def validate_approval
    post.lock!

    if post.is_status_locked?
      errors.add(:post, "is locked and cannot be approved")
    end

    if post.status == "active"
      errors.add(:post, "is already active and cannot be approved")
    end
  end

  concerning(:SearchMethods) do
    class_methods do
      def post_tags_match(query, user)
        where(post_id: Post.tag_match_sql(query, user))
      end

      def query_dsl
        super
          .field(:post_id)
          .field(:ip_addr, :user_ip_addr)
          .custom(:post_tags_match, ->(q, v, user) { q.post_tags_match(v, user) })
          .association(:user)
          .association(:post)
      end
    end
  end

  def self.available_includes
    %i[post user]
  end
end
