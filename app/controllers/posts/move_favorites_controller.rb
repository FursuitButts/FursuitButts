# frozen_string_literal: true

module Posts
  class MoveFavoritesController < ApplicationController
    respond_to(:html, :json)

    def show
      @post = authorize(Post.find(params[:id]), :move_favorites?)
      respond_with(@post)
    end

    def create
      @post = authorize(Post.find(params[:id]), :move_favorites?)
      @post.give_favorites_to_parent(CurrentUser.user)
      @post.give_votes_to_parent(CurrentUser.user)
      respond_with(@post)
    end
  end
end
