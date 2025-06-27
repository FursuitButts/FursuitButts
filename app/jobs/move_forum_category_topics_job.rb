# frozen_string_literal: true

class MoveForumCategoryTopicsJob < ApplicationJob
  queue_as(:default)

  def perform(user, old_category, new_category)
    old_can_create = old_category.can_create
    old_category.update(can_create: User::Levels::LOCKED, updater: user.resolvable)
    old_category.topics.find_each do |topic|
      topic.update_columns(category_id: new_category.id)
    end
  ensure
    old_category.update(can_create: old_can_create, updater: user.resolvable)
    ModAction.log!(user.resolvable, :forum_category_topics_move, old_category, forum_category_id: new_category.id, forum_category_name: new_category.name, can_view: new_category.can_view, old_forum_category_id: old_category.id, old_forum_category_name: old_category.name, old_can_view: old_category.can_view)
  end
end
