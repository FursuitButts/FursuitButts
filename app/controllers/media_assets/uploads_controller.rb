# frozen_string_literal: true

module MediaAssets
  class UploadsController < BaseController
    def finalize
      @asset = authorize(asset_class.find(params[:id]))
      @asset.finalize!
      @asset.reload_post
      return respond_with(@asset) if @asset.errors.any?
      return render(json: { success: false, reason: "duplicate", location: post_path(@asset.duplicate_post_id), post_id: @asset.duplicate_post_id }, status: :precondition_failed) if @asset.duplicate?
      return respond_with(@asset) if @asset.upload.blank?
      return render_expected_error(422, "post wasn't created?") if @asset.post.blank?
      render(json: { success: true, location: post_path(@asset.post.id), post_id: @asset.post.id, upload_id: @asset.upload.id })
    end

    protected

    def asset_class
      UploadMediaAsset
    end
  end
end
