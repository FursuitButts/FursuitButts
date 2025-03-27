# frozen_string_literal: true

class BulkUpdateRequestsController < ApplicationController
  respond_to :html, :json
  before_action :load_bulk_update_request, except: %i[new create index]
  before_action :ensure_lockdown_disabled, except: %i[index show]

  def index
    @bulk_update_requests = authorize(BulkUpdateRequest).html_includes(request, :forum_post, :creator, :approver)
                                                        .search(search_params(BulkUpdateRequest))
                                                        .paginate(params[:page], limit: params[:limit])
    respond_with(@bulk_update_requests)
  end

  def show
    @bulk_update_request = authorize(BulkUpdateRequest.find(params[:id]))
    respond_with(@bulk_update_request)
  end

  def new
    @bulk_update_request = authorize(BulkUpdateRequest.new)
    respond_with(@bulk_update_request)
  end

  def edit
    authorize(@bulk_update_request)
  end

  def create
    @bulk_update_request = authorize(BulkUpdateRequest.new(permitted_attributes(BulkUpdateRequest)))
    @bulk_update_request.save
    respond_with(@bulk_update_request)
  end

  def update
    authorize(@bulk_update_request)
    @bulk_update_request.should_validate = true
    @bulk_update_request.update(permitted_attributes(@bulk_update_request))
    notice("Bulk update request updated")
    respond_with(@bulk_update_request)
  end

  def approve
    authorize(@bulk_update_request).approve!(CurrentUser.user)
    notice(@bulk_update_request.valid? ? "Bulk update approved" : @bulk_update_request.errors.full_messages.join("; "))
    respond_with(@bulk_update_request)
  end

  def destroy
    authorize(@bulk_update_request).reject!(CurrentUser.user)
    notice("Bulk update request rejected")
    respond_with(@bulk_update_request, location: bulk_update_requests_path)
  end

  private

  def load_bulk_update_request
    @bulk_update_request = BulkUpdateRequest.find(params[:id])
  end

  def ensure_lockdown_disabled
    access_denied if Security::Lockdown.aiburs_disabled? && !CurrentUser.is_staff?
  end
end
