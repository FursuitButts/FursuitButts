# frozen_string_literal: true

class UploadsController < ApplicationController
  before_action :ensure_uploads_enabled, only: %i[new create]
  respond_to :html, :json
  content_security_policy only: [:new] do |p|
    p.img_src(:self, :data, :blob, "*")
    p.media_src(:self, :data, :blob, "*")
  end

  def index
    @uploads = authorize(Upload).search(search_params(Upload)).includes(:post, :uploader).paginate(params[:page], limit: params[:limit])
    respond_with(@uploads)
  end

  def show
    @upload = authorize(Upload.find(params[:id]))
    respond_with(@upload) do |format|
      format.html do
        if @upload.is_completed? && @upload.post_id
          redirect_to(post_path(@upload.post_id))
        end
      end
    end
  end

  def new
    @upload = authorize(Upload.new)
    if CurrentUser.can_upload_with_reason == :REJ_UPLOAD_NEWBIE
      return access_denied("You can not upload during your first three days.")
    end
    respond_with(@upload)
  end

  def create
    authorize(Upload)
    Post.transaction do
      @service = UploadService.new(permitted_attributes(Upload).merge(uploader_id: CurrentUser.id, uploader_ip_addr: CurrentUser.ip_addr))
      @upload = @service.start!
    end

    if @upload.invalid?
      flash.now[:notice] = @upload.errors.full_messages.join("; ")
      return render(json: { success: false, reason: "invalid", message: @upload.errors.full_messages.join("; ") }, status: 412)
    end
    if @service.warnings.any? && !@upload.is_errored? && !@upload.is_duplicate?
      warnings = @service.warnings.join(".\n \n")
      if warnings.length > 1500
        Dmail.create_automated({
          to_id: CurrentUser.id,
          title: "Upload notices for post ##{@service.post.id}",
          body:  "While uploading post ##{@service.post.id} some notices were generated. Please review them below:\n\n#{warnings}",
        })
        flash[:notice] = "This upload created a LOT of notices. They have been dmailed to you. Please review them"
      else
        flash[:notice] = warnings
      end
    end

    respond_to do |format|
      format.json do
        return render(json: { success: false, reason: "duplicate", location: post_path(@upload.duplicate_post_id), post_id: @upload.duplicate_post_id }, status: 412) if @upload.is_duplicate?
        return render(json: { success: false, reason: "invalid", message: @upload.sanitized_status }, status: 412) if @upload.is_errored?

        render(json: { success: true, location: post_path(@upload.post_id), post_id: @upload.post_id })
      end
    end
  end

  private

  def ensure_uploads_enabled
    access_denied if Security::Lockdown.uploads_disabled? || CurrentUser.user.level < Security::Lockdown.uploads_min_level
  end
end
