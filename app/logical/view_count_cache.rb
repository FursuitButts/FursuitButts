# frozen_string_literal: true

module ViewCountCache
  module_function

  def add!(post_id, count, type)
    RequestStore.store[:"view_count_#{type}_cache"] ||= {}
    RequestStore.store[:"view_count_#{type}_cache"][post_id] = count
  end

  def add_all!(hash, type)
    RequestStore.store[:"view_count_#{type}_cache"] ||= {}
    RequestStore.store[:"view_count_#{type}_cache"].merge!(hash)
  end

  def get(post_id, type)
    value = RequestStore.store.dig(:"view_count_#{type}_cache", post_id)
    return value if value.present?

    # Daily views should not be deduped as this can cause views to not show up
    value = Reports.get_post_views(post_id, date: type == :daily ? Time.now : nil, unique: type == :daily ? false : CurrentUser.user.unique_views?)
    add!(post_id, value, type)
    value
  end
end
