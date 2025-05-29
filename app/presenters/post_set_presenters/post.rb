# frozen_string_literal: true

module PostSetPresenters
  class Post < Base
    attr_accessor(:post_set)

    delegate(:posts, to: :post_set)

    def initialize(post_set)
      @post_set = post_set
    end

    def tag_set_presenter
      @tag_set_presenter ||= TagSetPresenter.new(related_tags)
    end

    def post_previews_html(template, options = {})
      super(template, options.merge(show_cropped: true))
    end

    def related_tags
      RelatedTagCalculator.calculate_from_posts_to_array(post_set.posts).map(&:first)
    end

    def post_index_sidebar_tag_list_html(current_query:)
      tag_set_presenter.post_index_sidebar_tag_list_html(current_query: current_query, followed_tags: CurrentUser.user.followed_tags.joins(:tag).where("tags.name": related_tags).map(&:tag_name))
    end
  end
end
