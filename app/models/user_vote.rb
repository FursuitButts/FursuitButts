# frozen_string_literal: true

class UserVote < ApplicationRecord
  class Error < StandardError; end

  self.abstract_class = true

  scope(:for_user, ->(user) { where(user_id: u2id(user)) })

  def self.inherited(child_class)
    super
    return if child_class.name.starts_with?("Lockable") # We can't check for abstract here, it hasn't been set yet
    child_class.class_eval do
      belongs_to(model_type)
      belongs_to_user(:user, ip: true, counter_cache: "#{child_class.name.underscore}_count")
    end
  end

  # PostVote => :post
  def self.model_type
    model_name.singular.delete_suffix("_vote").to_sym
  end

  def self.model
    name.delete_suffix("Vote").constantize
  end

  def self.vote_types
    [%w[Downvote -1 text-red], %w[Upvote 1 text-green]]
  end

  def is_positive?
    score == 1
  end

  def is_negative?
    score == -1
  end

  def vote_type
    case score
    when 1
      "up"
    when -1
      "down"
    else
      raise
    end
  end

  def vote_display
    self.class.vote_types.to_h { |type, value, klass| [value, %(<span class="#{klass}">#{type.titleize}</span>)] }[score.to_s]
  end

  module SearchMethods
    def search(params, user)
      q = super

      if params["#{model_type}_id"].present?
        q = q.where("#{model_type}_id" => params["#{model_type}_id"].split(",").first(100))
      end

      q = q.where_user(:user_id, :user, params)

      allow_complex_params = params.keys.intersect?(%W[#{model_type}_id user_name user_id])

      if allow_complex_params
        q = q.where_user({ model_type => :"#{model_creator_column}_id" }, :"#{model_type}_creator", params) do |q, _user_ids|
          q.joins(model_type)
        end

        if params[:timeframe].present?
          q = q.where("#{table_name}.updated_at >= ?", params[:timeframe].to_i.days.ago)
        end

        if params[:ip_addr].present?
          q = q.where("user_ip_addr <<= ?", params[:ip_addr])
        end

        if params[:score].present?
          q = q.where("#{table_name}.score = ?", params[:score])
        end

        if params[:duplicates_only].to_s.truthy?
          subselect = search(user, params.except("duplicates_only")).select(:user_ip_addr).group(:user_ip_addr).having("count(user_ip_addr) > 1").reorder("")
          q = q.where(user_ip_addr: subselect)
        end
      end

      if params[:order] == "ip_addr" && allow_complex_params
        q = q.order(:user_ip_addr)
      else
        q = q.apply_basic_order(params)
      end
      q
    end
  end

  extend(SearchMethods)

  def visible?(user)
    user.is_moderator? || user_id == user.id
  end

  def self.controller
    {
      "CommentVote"   => "comments/votes",
      "ForumPostVote" => "forums/posts/votes",
      "PostVote"      => "posts/votes",
    }.fetch(name)
  end
end
