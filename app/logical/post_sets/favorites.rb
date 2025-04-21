# frozen_string_literal: true

module PostSets
  class Favorites < PostSets::Base
    attr_reader :page, :limit

    def initialize(user, page, limit:)
      super()
      @user = user
      @page = page
      @limit = limit
    end

    def public_tag_string
      "fav:#{@user.name}"
    end

    def current_page
      [page.to_i, 1].max
    end

    def favorites
      @post_count ||= ::Post.tag_match("fav:#{@user.name} status:any").count_only
      @favorites ||= ::Favorite.for_user(@user.id).includes(:post).order(created_at: :desc).paginate_posts(page, total_count: @post_count, limit: @limit)
    end

    def posts
      new_opts = { pagination_mode: :numbered, records_per_page: favorites.records_per_page, total_count: @post_count, current_page: current_page }
      FemboyFans::Paginator::PaginatedArray.new(favorites.map(&:post), new_opts)
    end

    def api_posts
      favorites = self.favorites
      fill_children(favorites)
      favorites
    end

    def fill_children(favorites)
      super(favorites.map(&:post))
    end

    def tag_array
      []
    end

    def presenter
      ::PostSetPresenters::Post.new(self)
    end
  end
end
