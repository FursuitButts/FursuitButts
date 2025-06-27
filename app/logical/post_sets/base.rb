# frozen_string_literal: true

module PostSets
  class Base
    attr_reader(:current_user)

    def initialize(current_user)
      @current_user = current_user
    end

    def tag_string
      ""
    end

    def public_tag_string
      ""
    end

    def fill_children(posts)
      posts = posts.filter(&:has_children?)
      ids = posts.map(&:id)
      children = ::Post.select(%i[id parent_id]).where(parent_id: ids).to_a.group_by(&:parent_id)
      posts.each do |p|
        p.inject_children(children[p.id] || [])
      end
    end

    def presenter
      raise(NotImplementedError)
    end

    def load_view_counts!
      daily = Reports.get_bulk_post_views(posts.map(&:id), date: Time.now, unique: current_user.unique_views?)
      total = Reports.get_bulk_post_views(posts.map(&:id), unique: current_user.unique_views?)
      ViewCountCache.add_all!(daily, :daily)
      ViewCountCache.add_all!(total, :total)
    end
  end
end
