# frozen_string_literal: true

class PopularController < ApplicationController
  respond_to :html, :json

  def index
  end

  def uploads
    @date, @scale, @min_date, @max_date = parse_date(params)
    @post_set = PostSets::Popular::Uploads.new(@date, @scale, @min_date, @max_date, limit: limit)
    @posts = @post_set.posts
    respond_with(@posts)
  end

  def views
    @date, @scale, @min_date, @max_date = parse_date(params, scales: %w[day])
    @post_set = PostSets::Popular::Views.new(@date, limit: limit)
    @posts = @post_set.posts
    respond_with(@posts)
  end

  def searches
    @date, @scale, @min_date, @max_date = parse_date(params, scales: %w[day])
    @ranking = Reports.get_post_searches_rank(@date, limit: limit).first(limit)
    respond_with(@ranking, &format_json(@ranking))
  end

  def missed_searches
    @date, @scale, @min_date, @max_date = parse_date({}, scales: %w[day])
    @ranking = Reports.get_missed_searches_rank(limit: limit)
    respond_with(@ranking, &format_json(@ranking))
  end

  def followed_tags
    @tags = Tag.order(follower_count: :desc, name: :asc).paginate(params[:page], limit: limit)
    respond_with(@tags)
  end

  private

  def parse_date(params, scales: %w[day week month])
    date = params[:date].present? ? Date.parse(params[:date]) : Time.now
    scale = params[:scale].in?(scales) ? params[:scale] : "day"
    min_date = date.send("beginning_of_#{scale}")
    max_date = date.send("next_#{scale}").send("beginning_of_#{scale}")

    [date, scale, min_date, max_date]
  end

  def popular_posts(min_date, max_date)
    Post.where(created_at: min_date..max_date).tag_match("order:score")
  end

  def limit(default: 100, min: 1, max: default)
    params.fetch(:limit, default).to_i.clamp(min..max)
  end
end
