# frozen_string_literal: true

module Users
  class RevertsController < ApplicationController
    def new
      authorize(UserRevert)
      @user = User.find(params[:user_id])
    end

    def create
      user = User.find(params[:user_id])
      revert = authorize(UserRevert.new(user.id, CurrentUser.user))
      revert.process
      respond_to do |format|
        format.html { redirect_to(user_path(user.id)) }
        format.json
      end
    end
  end
end
