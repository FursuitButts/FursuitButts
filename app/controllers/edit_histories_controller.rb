# frozen_string_literal: true

class EditHistoriesController < ApplicationController
  respond_to :html

  def index
    @edit_histories = authorize(EditHistory).html_includes(request, :user)
                                            .search(search_params(EditHistory))
                                            .paginate(params[:page], limit: params[:limit])
    respond_with(@edit_histories)
  end

  def show
    @edit_histories = authorize(EditHistory).html_includes(request, :user)
                                            .where(versionable_id: params[:id], versionable_type: params[:type])
    @original = @edit_histories.original
    @edit_histories = @edit_histories.order(id: :asc).paginate(params[:page], limit: params[:limit])
    @content_edits = @edit_histories.select(&:is_contentful?)
    respond_with(@edit_histories)
  end

  def diff
    if params[:otherversion].blank? || params[:thisversion].blank?
      redirect_back(fallback_location: { action: :index }, notice: "You must select two versions to diff")
      return
    end

    @otherversion = authorize(EditHistory.find(params[:otherversion]))
    @thisversion = authorize(EditHistory.find(params[:thisversion]))
    redirect_back(fallback_location: { action: :index }, notice: "You cannot diff different versionables") if @otherversion.versionable_type != @thisversion.versionable_type || @otherversion.versionable_id != @thisversion.versionable_id
  end
end
