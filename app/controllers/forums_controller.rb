# frozen_string_literal: true

class ForumsController < ApplicationController
  respond_to :html, :json

  def index
    @forum_categories = authorize(ForumCategory).visible.ordered_categories.paginate(params[:page], limit: params[:limit] || 50)
    respond_with(@forum_categories)
  end
end
