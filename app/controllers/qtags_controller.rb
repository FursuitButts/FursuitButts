# frozen_string_literal: true

class QtagsController < ApplicationController
  respond_to(:json, :html)

  def show
    @posts = Post.where.any(qtags: params[:id]).paginate(params[:page], limit: params[:limit])
    respond_with(@posts)
  end
end
