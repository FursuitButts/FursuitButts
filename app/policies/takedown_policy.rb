# frozen_string_literal: true

class TakedownPolicy < ApplicationPolicy
  def create?
    true
  end

  def show?
    true
  end

  def update?
    user.can_handle_takedowns?
  end

  def destroy?
    user.can_handle_takedowns?
  end

  def add_by_ids?
    user.can_handle_takedowns?
  end

  def add_by_tags?
    user.can_handle_takedowns?
  end

  def count_matching_posts?
    user.can_handle_takedowns?
  end

  def remove_by_ids?
    user.can_handle_takedowns?
  end

  def permitted_attributes
    params = %i[email source instructions reason post_ids reason_hidden]
    params += %i[notes del_post_ids status] if user.can_handle_takedowns?
    [*params, { post_ids: [] }]
  end

  def permitted_search_params
    params = (super - %i[order]) + %i[status] + nested_search_params(approver: User)
    params += %i[source reason creator_id creator_name reason_hidden instructions post_id notes] + nested_search_params(updater: User, approver: User) if user.can_handle_takedowns? || user.is_staff?
    params += %i[ip_addr] if can_search_ip_addr? && (user.can_handle_takedowns? || user.is_staff?)
    params += %i[email vericode order] if user.can_handle_takedowns?
    params
  end

  def api_attributes
    attr = super
    attr -= %i[source reason notes] unless !record.reason_hidden || user.is_janitor?
    attr -= %i[creator_id instructions] unless user.is_janitor?
    attr -= %i[email vericode post_ids del_post_ids] unless user.can_handle_takedowns?
    attr
  end

  def html_data_attributes
    super + %i[status]
  end
end
