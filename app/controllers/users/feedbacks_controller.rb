# frozen_string_literal: true

module Users
  class FeedbacksController < ApplicationController
    respond_to :html, :json

    def index
      @user_feedbacks = authorize(UserFeedback).html_includes(request, :user, :creator)
                                               .search(search_params(UserFeedback))
                                               .paginate(params[:page], limit: params[:limit])
      respond_with(@user_feedbacks)
    end

    def show
      @user_feedback = authorize(UserFeedback.find(params[:id]))
      respond_with(@user_feedback)
    end

    def new
      @user_feedback = authorize(UserFeedback.new(permitted_attributes(UserFeedback)))
      respond_with(@user_feedback)
    end

    def edit
      @user_feedback = authorize(UserFeedback.find(params[:id]))
      respond_with(@user_feedback)
    end

    def create
      @user_feedback = authorize(UserFeedback.new(permitted_attributes(UserFeedback)))
      @user_feedback.save
      respond_with(@user_feedback)
    end

    def update
      @user_feedback = authorize(UserFeedback.find(params[:id]))
      params_update = permitted_attributes(@user_feedback)

      @user_feedback.update(params_update)
      not_changed = params_update[:send_update_dmail].to_s.truthy? && !@user_feedback.saved_change_to_body?
      notice("Not sending update, body not changed") if not_changed
      respond_with(@user_feedback)
    end

    def delete
      @user_feedback = authorize(UserFeedback.find(params[:id]))
      @user_feedback.update(is_deleted: true)
      flash[:notice] = @user_feedback.errors.any? ? @user_feedback.errors.full_messages.join("; ") : "Feedback deleted"
      respond_with(@user_feedback) do |format|
        format.html { redirect_back(fallback_location: user_feedbacks_path(search: { user_id: @user_feedback.user_id })) }
      end
    end

    def undelete
      @user_feedback = authorize(UserFeedback.find(params[:id]))
      @user_feedback.update(is_deleted: false)
      flash[:notice] = @user_feedback.errors.any? ? @user_feedback.errors.full_messages.join("; ") : "Feedback undeleted"
      respond_with(@user_feedback) do |format|
        format.html { redirect_back(fallback_location: user_feedbacks_path(search: { user_id: @user_feedback.user_id })) }
      end
    end

    def destroy
      @user_feedback = authorize(UserFeedback.find(params[:id]))
      @user_feedback.destroy
      respond_with(@user_feedback) do |format|
        format.html { redirect_back(fallback_location: user_feedbacks_path) }
      end
    end
  end
end
