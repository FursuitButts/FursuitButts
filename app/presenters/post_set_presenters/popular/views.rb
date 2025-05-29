# frozen_string_literal: true

module PostSetPresenters
  module Popular
    class Views < Base
      attr_accessor(:post_set, :tag_set_presenter)

      delegate(:posts, :date, to: :post_set)

      def initialize(post_set)
        @post_set = post_set
      end

      def next_date
        date + 1.day
      end

      def prev_date
        date - 1.day
      end

      def nav_links(template)
        html =  []
        html << "<p id=\"popular-nav-links\">"
        html << "<span class=\"period\">"
        html << template.link_to(
          "«prev",
          template.views_popular_index_path(
            date: prev_date.strftime("%Y-%m-%d"),
          ),
          "id":            "paginator-prev",
          "rel":           "prev",
          "data-shortcut": "a left",
        )
        html << template.link_to(
          "Day",
          template.views_popular_index_path(
            date: date.strftime("%Y-%m-%d"),
          ),
          class: "desc",
        )
        html << template.link_to(
          "next»",
          template.views_popular_index_path(
            date: next_date.strftime("%Y-%m-%d"),
          ),
          "id":            "paginator-next",
          "rel":           "next",
          "data-shortcut": "d right",
        )
        html << "</span>"
        html << "<span class=\"period\">"
        html << template.link_to("All Time", template.top_views_popular_index_path)
        html << "</span>"
        html << "</p>"
        html.join("\n").html_safe
      end

      def range_text
        date.strftime("%B %Y")
      end
    end
  end
end
