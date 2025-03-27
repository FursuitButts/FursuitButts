# frozen_string_literal: true

module Moderator
  class UserApprovalsController < ApplicationController
    respond_to :html, :json

    def index
      @user_approvals = authorize(UserApproval).html_includes(request, :user, :updater)
                                               .search(search_params(UserApproval))
                                               .paginate(params[:page], limit: params[:limit])
    end

    def approve
      @user_approval = authorize(UserApproval.find(params[:id]))

      @user_approval.approve!
      if @user_approval.errors.empty?
        flash[:notice] = "User approved"
      else
        flash[:notice] = @user_approval.errors.full_messages.join("; ")
      end
      respond_with(@user_approval) do |fmt|
        fmt.html { redirect_back(fallback_location: { action: :index }) }
      end
    end

    def reject
      @user_approval = authorize(UserApproval.find(params[:id]))
      @user_approval.reject!
      if @user_approval.errors.empty?
        flash[:notice] = "User rejected"
      else
        flash[:notice] = @user_approval.errors.full_messages.join("; ")
      end
      respond_with(@user_approval) do |fmt|
        fmt.html { redirect_back(fallback_location: { action: :index }) }
      end
    end
  end
end
