# frozen_string_literal: true

ClickHouse.config do |config|
  config.url = FemboyFans.config.clickhouse_url
end
