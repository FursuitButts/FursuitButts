# frozen_string_literal: true

module Reports
  module_function

  LIMIT = 100

  def enabled?
    !Rails.env.test? && FemboyFans.config.reports_enabled?
  end

  def get(path)
    response = Faraday.new(FemboyFans.config.faraday_options.deep_merge(headers: { authorization: "Bearer #{jwt_signature(path)}" })).get("#{FemboyFans.config.reports_server_internal}#{path}")
    JSON.parse(response.body)
  end

  # Integer
  def get_post_views(post_id, date: nil, unique: false)
    return 0 unless enabled?
    d = date&.strftime("%Y-%m-%d")
    q = { date: d, unique: unique }.compact_blank.to_query
    Cache.fetch("pv-#{post_id}-#{d}-#{unique}", expires_in: 1.minute) do
      get("/views/#{post_id}?#{q}")["data"].to_i
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError
    0
  end

  # Hash { "post" => 0, "count" => 0 }[]
  def get_post_views_rank(date, limit: LIMIT, unique: false)
    return [] unless enabled?
    d = date.strftime("%Y-%m-%d")
    q = { date: d, limit: limit, unique: unique }.compact_blank.to_query
    Cache.fetch("pv-rank-#{d}-#{unique}", expires_in: 1.minute) do
      get("/views/rank?#{q}")["data"]
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError
    []
  end

  # Hash { "tag" => "name", "count" => 0 }[]
  def get_post_searches_rank(date, limit: LIMIT)
    return [] unless enabled?
    Cache.fetch("ps-rank-#{date}", expires_in: 1.minute) do
      get("/searches/rank?date=#{date.strftime('%Y-%m-%d')}&limit=#{limit}")["data"]
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError
    []
  end

  # Hash { "tag" => "name", "count" => 0 }[]
  def get_missed_searches_rank(limit: LIMIT)
    return [] unless enabled?
    Cache.fetch("ms-rank", expires_in: 1.minute) do
      get("/searches/missed/rank?limit=#{limit}")["data"]
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError
    []
  end

  # Hash { post_id => count }
  def get_bulk_post_views(post_ids, date: nil, unique: false)
    return {} unless enabled?
    d = date&.strftime("%Y-%m-%d")
    post_ids.each_slice(100).flat_map do |ids|
      q = { date: d, unique: unique, posts: ids.join(",") }.compact_blank.to_query
      get("/views/bulk?#{q}")["data"]
    end.compact_blank.to_h { |x| [x["post"], x["count"]] }
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError
    {}
  end

  def jwt_signature(url)
    JWT.encode({
      iss: "FemboyFans",
      iat: Time.now.to_i,
      exp: 1.minute.from_now.to_i,
      aud: "Reports",
      sub: url.split("?").first,
    }, FemboyFans.config.report_key, "HS256")
  end

  PostView = Struct.new(:id, :post_id, :ip_address, :date)
  MissedSearch = Struct.new(:id, :tags, :page, :date)
  Search = Struct.new(:id, :tags, :page, :date)

  def get_all_post_views
    ClickHouse.connection.select_all("SELECT post_id, COUNT(*) as count FROM post_views GROUP BY (post_id)").to_h { |v| [v["post_id"], v["count"]] }
  end

  def get_views_for_posts(post_ids)
    ClickHouse.connection.select_all("SELECT post_id, COUNT(*) as count FROM post_views WHERE post_id IN (#{post_ids.join(', ')}) GROUP BY (post_id)").to_h { |v| [v["post_id"], v["count"]] }
  end
end
