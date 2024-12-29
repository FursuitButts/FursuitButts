# frozen_string_literal: true

class ForumCategoryVisit < ApplicationRecord
  belongs_to :user
  belongs_to :forum_category

  def self.available_includes
    %i[forum_category user]
  end
end
