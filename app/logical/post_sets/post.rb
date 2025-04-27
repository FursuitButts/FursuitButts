# frozen_string_literal: true

module PostSets
  class Post < PostSets::Base
    attr_reader :tag_array, :public_tag_array, :page, :limit, :random, :post_count

    def initialize(tags, page = 1, limit: nil, random: nil)
      super()
      tags ||= ""
      @public_tag_array = apply_ratio_tags(TagQuery.scan(tags))
      tags += " rating:s" if CurrentUser.safe_mode?
      tags += " -status:deleted" unless TagQuery.has_metatag?(tags, "status", "-status")
      @tag_array = apply_ratio_tags(TagQuery.scan(tags))
      @page = page
      @limit = limit || TagQuery.fetch_metatag(tag_array, "limit")
      @random = random.present?
    end

    def apply_ratio_tags(tags)
      tags.map do |tag|
        next "#{$1}ratio:#{$2}:#{$3}" if tag =~ /^([~-])?([\d.]+):([\d.]+)$/
        tag
      end
    end

    def tag_string
      @tag_string ||= tag_array.uniq.join(" ")
    end

    def public_tag_string
      @public_tag_string ||= public_tag_array.uniq.join(" ")
    end

    def humanized_tag_string
      public_tag_array.slice(0, 25).join(" ").tr("_", " ")
    end

    def has_explicit?
      !CurrentUser.safe_mode?
    end

    def hidden_posts
      @hidden_posts ||= posts.reject(&:visible?)
    end

    def login_blocked_posts
      @login_blocked_posts ||= posts.select(&:loginblocked?)
    end

    def safe_posts
      @safe_posts ||= posts.select { |p| p.safeblocked? && !p.deleteblocked? }
    end

    def is_random?
      random || (TagQuery.fetch_metatag(tag_array, "order") == "random" && !TagQuery.has_metatag?(tag_array, "randseed"))
    end

    def is_simple_tags?
      return false if %w[~ *].any? { |c| public_tag_string.include?(c) }
      return false if public_tag_string.split.any? { |tag| TagQuery::METATAGS.include?(tag.split(":")[0]) }
      true
    end

    def posts
      @posts ||= begin
        temp = ::Post.tag_match(tag_string).paginate_posts(page, limit: limit, includes: %i[uploader media_asset])

        @post_count = temp.total_count
        temp
      end
    end

    def api_posts
      posts = self.posts
      fill_children(posts)
      posts
    end

    def current_page
      [page.to_i, 1].max
    end

    def presenter
      @presenter ||= ::PostSetPresenters::Post.new(self)
    end
  end
end
