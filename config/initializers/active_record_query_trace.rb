# frozen_string_literal: true

if Rails.env.development?
  ActiveRecordQueryTrace.enabled = false
  ActiveRecordQueryTrace.lines = 0
  ActiveRecordQueryTrace.colorize = :cyan
  ActiveRecordQueryTrace.ignore_cached_queries = true
end
