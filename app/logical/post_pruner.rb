# frozen_string_literal: true

class PostPruner
  MODERATION_WINDOW = 7

  def prune!
    Post.without_timeout do
      CurrentUser.as_system do
        prune_pending!
        prune_appealed!
      end
    end
  end

  protected

  def prune_pending!
    Post.pending.not_deleted.expired.find_each do |post|
      post.delete!("Unapproved in #{MODERATION_WINDOW} days", force: true)
    end
  end

  def prune_appealed!
    PostAppeal.pending.expired.find_each(&:reject!)
  end
end
