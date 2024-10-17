# frozen_string_literal: true

class ForumCategory < ApplicationRecord
  MAX_TOPIC_MOVE_COUNT = 1000
  has_many :forum_topics, -> { order(id: :desc) }, foreign_key: :category_id
  validates :name, uniqueness: { case_sensitive: false }, length: { minimum: 3, maximum: 100 }

  after_create :log_create
  after_update :log_update
  before_destroy :prevent_destroy_if_topics
  after_destroy :log_delete

  before_validation(on: :create) do
    self.order = (ForumCategory.maximum(:order) || 0) + 1 if order.blank?
  end

  attr_accessor :new_category_id # technical bullshit

  def can_create_within?(user = CurrentUser.user)
    user.level >= can_create
  end

  def self.reverse_mapping
    order(:order).all.map { |rec| [rec.name, rec.id] }
  end

  def self.ordered_categories
    order(:order)
  end

  def prevent_destroy_if_topics
    if forum_topics.any?
      errors.add(:base, "Forum category cannot be deleted because it has topics")
      throw(:abort)
    end
  end

  module LogMethods
    def log_create
      ModAction.log!(:forum_category_create, self,
                     forum_category_name: name,
                     can_view:            can_view,
                     can_create:          can_create)
    end

    def log_update
      ModAction.log!(:forum_category_update, self,
                     forum_category_name:     name,
                     old_forum_category_name: name_before_last_save,
                     can_view:                can_view,
                     old_can_view:            can_view_before_last_save,
                     can_create:              can_create,
                     old_can_create:          can_create_before_last_save)
    end

    def log_delete
      ModAction.log!(:forum_category_delete, self,
                     forum_category_name: name,
                     can_view:            can_view,
                     can_create:          can_create)
    end
  end

  def self.log_reorder(total)
    ModAction.log!(:forum_categories_reorder, nil, total: total)
  end

  module SearchMethods
    def visible
      where(can_view: ..CurrentUser.user.level)
    end
  end

  include LogMethods
  extend SearchMethods

  def visible?(user = CurrentUser.user)
    user.level >= can_view
  end

  def can_move_topics?
    forum_topics.count <= ForumCategory::MAX_TOPIC_MOVE_COUNT
  end

  def move_all_topics(new_category, user: CurrentUser.user)
    return if forum_topics.empty?
    MoveForumCategoryTopicsJob.perform_later(user, self, new_category)
  end
end
