# frozen_string_literal: true

class PostSetMaintainer < ApplicationRecord
  belongs_to_user(:user)
  belongs_to(:post_set)

  validate(:ensure_not_set_owner, on: :create)
  validate(:ensure_set_public, on: :create)
  validate(:ensure_maintainer_count, on: :create)
  validate(:ensure_not_duplicate, on: :create)

  after_create(:notify_maintainer)

  def notify_maintainer
    r = Rails.application.routes.url_helpers
    body = <<~BODY.chomp
      "#{post_set.creator.name}":#{r.users_path(post_set.creator_id)} invited you to be a maintainer of the "#{post_set.name}":#{r.post_set_path(post_set_id)} set. This would allow you to add and remove posts from it.

      "Click here":#{r.approve_post_set_maintainer_path(self)} to approve the request and become a maintainer.

      "Click here":#{r.deny_post_set_maintainer_path(self)} to deny the request.

      "Click here":#{r.block_post_set_maintainer_path(self)} to deny the request and prevent yourself from being invited to this set again in the future.
    BODY

    Dmail.create_automated(
      to_id:         user_id,
      title:         "You were invited to be a maintainer of #{post_set.name}",
      body:          body,
      respond_to_id: post_set.creator_id,
    )
  end

  def cancel!
    if status == "pending"
      self.status = "cooldown"
      save
      return
    end

    if status == "approved"
      body = "\"#{post_set.creator.name}\":/users/#{post_set.creator_id} removed you as a maintainer of the \"#{post_set.name}\":/post_sets/#{post_set.id} set."
      Dmail.create_automated(
        to_id:         user_id,
        title:         "You were removed as a set maintainer of #{post_set.name}",
        body:          body,
        respond_to_id: post_set.creator_id,
      )
    end
    destroy
  end

  def approve!
    self.status = "approved"
    save
    Dmail.create_automated(
      to_id:         post_set.creator_id,
      title:         "#{user.name} accepted your invite to maintain #{post_set.name}",
      body:          "\"#{user.name}\":/users/#{user_id} approved your invite to maintain \"#{post_set.name}\":/post_sets/#{post_set.id}.",
      respond_to_id: user.id,
    )
  end

  def deny!
    if status == "pending"
      Dmail.create_automated(
        to_id:         post_set.creator_id,
        title:         "#{user.name} declined your invite to maintain #{post_set.name}",
        body:          "\"#{user.name}\":/users/#{user.id} denied your invite to maintain \"#{post_set.name}\":/post_sets/#{post_set.id}.",
        respond_to_id: user.id,
      )
    elsif status == "approved"
      Dmail.create_automated(
        to_id:         post_set.creator_id,
        title:         "#{user.name} removed themselves as a maintainer of #{post_set.name}",
        body:          "\"#{user.name}\":/users/#{user.id} removed themselves as a maintainer of \"#{post_set.name}\":/post_sets/#{post_set.id}.",
        respond_to_id: user.id,
      )
    end
    destroy
  end

  def block!
    if status == "approved"
      Dmail.create_automated(
        to_id:         post_set.creator_id,
        title:         "#{user.name} removed themselves as a maintainer of #{post_set.name}",
        body:          "\"#{user.name}\":/users/#{user.id} removed themselves as a maintainer of \"#{post_set.name}\":/post_sets/#{post_set.id} and blocked all future invites.",
        respond_to_id: user.id,
      )
    elsif status == "pending"
      Dmail.create_automated(
        to_id:         post_set.creator_id,
        title:         "#{user.name} denied your invite to maintain #{post_set.name}",
        body:          "\"#{user.name}\":/users/#{user.id} denied your invite to maintain \"#{post_set.name}\":/post_sets/#{post_set.id} and blocked all future invites.",
        respond_to_id: user.id,
      )
    end
    self.status = "blocked"
    save
  end

  module ValidaitonMethods
    def ensure_not_set_owner
      if post_set.creator_id == user_id
        errors.add(:user, "owns this set and can't be added as a maintainer")
        false
      end
    end

    def ensure_maintainer_count
      if PostSetMaintainer.where(post_set_id: post_set_id).count >= 75
        errors.add(:post_set, "current has too many maintainers")
        false
      end
    end

    def ensure_not_duplicate
      existing = PostSetMaintainer.where(post_set_id: post_set_id, user_id: user_id).first
      if existing.nil?
        return
      end
      if %w[approved pending].include?(existing.status)
        errors.add(:base, "Already a maintainer of this set")
        return false
      end
      if existing.status == "blocked"
        errors.add(:base, "User has blocked you from inviting them to maintain this set")
        return false
      end
      if existing.status == "cooldown" && existing.created_at > 24.hours.ago
        errors.add(:base, "User has been invited to maintain this set too recently")
        false
      end
    end

    def ensure_set_public
      unless post_set.is_public
        errors.add(:post_set, "must be public")
        false
      end
    end
  end

  def self.active
    where(status: "approved")
  end

  def self.pending
    where(status: "pending")
  end

  include(ValidaitonMethods)

  def self.available_includes
    %i[post_set user]
  end

  def visible?(user)
    user.id == user_id
  end
end
