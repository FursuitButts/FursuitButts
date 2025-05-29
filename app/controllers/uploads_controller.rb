# frozen_string_literal: true

class UploadsController < ApplicationController
  before_action(:ensure_uploads_enabled, only: %i[new create])
  respond_to(:html, :json)
  content_security_policy(only: [:new]) do |p|
    p.img_src(:self, :data, :blob, "*")
    p.media_src(:self, :data, :blob, "*")
  end

  def index
    # TODO: this route has many performance issues and needs to be revised
    @uploads = authorize(Upload).html_includes(request, :post, :uploader, :upload_media_asset)
                                .search(search_params(Upload))
                                .paginate(params[:page], limit: params[:limit])
    respond_with(@uploads)
  end

  def show
    @upload = authorize(Upload.find(params[:id]))
    respond_with(@upload) do |format|
      format.html do
        if @upload.active? && @upload.post_id
          redirect_to(post_path(@upload.post_id))
        end
      end
    end
  end

  def new
    @upload = authorize(Upload.new)
    if CurrentUser.can_upload_with_reason == :REJ_UPLOAD_NEWBIE
      return access_denied("You cannot upload during your first three days.")
    end
    respond_with(@upload)
  end

  def create
    @upload = authorize(Upload.new(permitted_attributes(Upload).merge(uploader_id: CurrentUser.id, uploader_ip_addr: CurrentUser.ip_addr)))
    @upload.save
    if @upload.invalid?
      flash.now[:notice] = @upload.errors.full_messages.join("; ")
      return render(json: { success: false, reason: "invalid", message: @upload.errors.full_messages.join("; ") }, status: 412)
    end
    return render(json: { success: true, id: @upload.id, media_asset_id: @upload.media_asset_id }, status: 202) unless @upload.is_direct?
    respond_after_upload
  end

  private

  def respond_after_upload
    if @upload.media_asset.expunged?
      return render(json: { success: false, reason: "invalid", message: "That image #{@upload.media_asset.status_message}" }, status: 412)
    end

    if @upload.errors.any?
      flash.now[:notice] = @upload.errors.full_messages.join("; ")
      return render(json: { success: false, reason: "invalid", message: @upload.errors.full_messages.join("; ") }, status: 412)
    end

    respond_to do |format|
      format.json do
        return render(json: { success: false, reason: "duplicate", location: post_path(@upload.duplicate_post_id), post_id: @upload.duplicate_post_id }, status: 412) if @upload.duplicate?
        return render(json: { success: false, reason: "invalid", message: @upload.pretty_status }, status: 412) if @upload.failed?

        render(json: { success: true, location: post_path(@upload.post_id), post_id: @upload.post_id })
      end
    end
  end

  def ensure_uploads_enabled
    access_denied if Security::Lockdown.uploads_disabled? || CurrentUser.user.level < Security::Lockdown.uploads_min_level
  end
end
