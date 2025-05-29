# frozen_string_literal: true

class UploadWhitelist < ApplicationRecord
  before_save(:clean_pattern)
  after_create(:log_create)
  after_update(:log_update)
  after_destroy(:log_delete)
  after_save(:clear_cache)

  validates(:pattern, presence: true)
  validates(:pattern, uniqueness: true)
  validates(:pattern, format: { with: %r{\A[a-zA-Z0-9.%:_\-*\/?&]+\z} })

  def clean_pattern
    self.pattern = pattern.downcase.tr("%", "*")
  end

  def clear_cache
    Cache.delete("upload_whitelist")
  end

  module LogMethods
    def log_create
      ModAction.log!(:upload_whitelist_create, self, pattern: pattern, note: note, hidden: hidden)
    end

    def log_update
      ModAction.log!(:upload_whitelist_update, self, pattern: pattern, note: note, old_pattern: pattern_before_last_save, hidden: hidden)
    end

    def log_delete
      ModAction.log!(:upload_whitelist_delete, self, pattern: pattern, note: note, hidden: hidden)
    end
  end

  module SearchMethods
    def default_order
      order("upload_whitelists.note")
    end

    def search(params)
      q = super

      if params[:pattern].present?
        q = q.where("pattern ILIKE ?", params[:pattern].to_escaped_for_sql_like)
      end

      if params[:note].present?
        q = q.where("note ILIKE ?", params[:note].to_escaped_for_sql_like)
      end

      case params[:order]
      when "pattern"
        q = q.order("upload_whitelists.pattern")
      when "updated_at"
        q = q.order("upload_whitelists.updated_at desc")
      when "created_at"
        q = q.order("id desc")
      else
        q = q.apply_basic_order(params)
      end

      q
    end
  end

  def self.is_whitelisted?(url)
    entries = Cache.fetch("upload_whitelist", expires_in: 6.hours) do
      all
    end

    if FemboyFans.config.bypass_upload_whitelist?(CurrentUser.user)
      return [true, "bypassed"]
    end

    entries.each do |x|
      if File.fnmatch?(x.pattern, url, File::FNM_CASEFOLD)
        return [x.allowed, x.reason]
      end
    end
    [false, "#{url.host} not in whitelist"]
  end

  include(LogMethods)
  extend(SearchMethods)
end
