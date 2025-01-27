# frozen_string_literal: true

module Users
  class DmailFiltersController < ApplicationController
    before_action :load_dmail, except: %i[show]
    before_action :load_dmail_filter
    respond_to :html, :json

    def show
      authorize(@dmail_filter)
      respond_with(@dmail_filter) do |format|
        format.html { redirect_to(edit_users_dmail_filter_path(dmail_id: params[:dmail_id])) }
      end
    end

    def edit
      authorize(@dmail, policy_class: DmailFilterPolicy)
    end

    def update
      authorize(@dmail, policy_class: DmailFilterPolicy)
      @dmail_filter.update(permitted_attributes(@dmail_filter))
      respond_with(@dmail_filter) do |format|
        format.html do
          notice("Filter updated")
          return redirect_to(dmail_path(@dmail)) if @dmail
          redirect_to(dmails_path)
        end
      end
    end

    private

    def load_dmail
      @dmail = Dmail.find_by(id: params[:dmail_id])
    end

    def load_dmail_filter
      @dmail_filter = CurrentUser.dmail_filter || DmailFilter.new
    end
  end
end
