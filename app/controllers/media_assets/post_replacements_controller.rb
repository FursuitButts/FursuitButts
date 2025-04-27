# frozen_string_literal: true

module MediaAssets
  class PostReplacementsController < BaseController
    def finalize
      @asset = authorize(asset_class.find(params[:id]))
      @asset.finalize!
      @asset.reload_post_replacement
      return respond_with(@asset) if @asset.errors.any?
      return render_expected_error(422, @asset.pretty_status) if @asset.failed?
      return respond_with(@asset) if @asset.post_replacement.blank?
      render(json: { success: true, location: post_path(@asset.post_replacement.post_id), post_id: @asset.post_replacement.post_id, post_replacement_id: @asset.post_replacement.id })
    end

    protected

    def asset_class
      PostReplacementMediaAsset
    end
  end
end
