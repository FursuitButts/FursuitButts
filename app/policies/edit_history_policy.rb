# frozen_string_literal: true

class EditHistoryPolicy < ApplicationPolicy
  def index?
    user.is_moderator?
  end

  def diff?
    index?
  end

  def permitted_search_params
    params = super + %i[versionable_type versionable_id edit_type updater_id updater_name]
    params += %i[ip_addr] if can_search_ip_addr?
    params
  end

  def api_attributes
    super - %i[extra_data] + record.json_keys
  end

  def html_data_attributes
    super + %i[edit_type is_contentful?]
  end
end
