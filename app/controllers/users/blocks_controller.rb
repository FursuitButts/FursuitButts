# frozen_string_literal: true

module Users
  class BlocksController < ApplicationController
    before_action(:load_user)
    respond_to(:html, :json)

    def index
      authorize(@user, policy_class: UserBlockPolicy)
      @blocks = UserBlock.html_includes(request, :target)
                         .where(user_id: params[:user_id])
                         .paginate(params[:page], limit: params[:limit])
      respond_with(@blocks)
    end

    def new
      authorize(@user, policy_class: UserBlockPolicy)
      @block = UserBlock.new(permitted_attributes(UserBlock))
    end

    def edit
      authorize(@user, policy_class: UserBlockPolicy)
      @block = UserBlock.find(params[:id])
    end

    def create
      authorize(@user, policy_class: UserBlockPolicy)
      @block = @user.blocks.create(permitted_attributes(UserBlock))
      respond_with(@block, location: user_blocks_path(@user)) do |format|
        format.html do
          flash[:notice] = @block.errors.any? ? "Failed to block user: #{@block.errors.full_messages.join('; ')}" : "Successfully blocked @#{@block.target_name}"
          redirect_to(user_blocks_path(@user))
        end
      end
    end

    def update
      authorize(@user, policy_class: UserBlockPolicy)
      @block = UserBlock.find(params[:id])
      @block.update(permitted_attributes(@block))
      respond_with(@block, location: user_blocks_path(@user)) do |format|
        format.html do
          flash[:notice] = @block.errors.any? ? "Failed to update block: #{@block.errors.full_messages.join('; ')}" : "Block for @#{@block.target_name} updated"
          redirect_to(user_blocks_path(@user))
        end
      end
    end

    def destroy
      authorize(@user, policy_class: UserBlockPolicy)
      @block = UserBlock.find(params[:id])
      @block.destroy
      respond_with(@block) do |format|
        format.html do
          flash[:notice] = "Unblocked @#{@block.target_name}"
          redirect_to(user_blocks_path(@user))
        end
      end
    end

    def load_user
      if params[:user_id] == "current" && !CurrentUser.user.is_anonymous?
        redirect_to(user_blocks_path(CurrentUser.user))
      else
        @user = User.find(params[:user_id])
      end
    end
  end
end
