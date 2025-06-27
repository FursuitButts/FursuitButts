# frozen_string_literal: true

module Users
  class CountFixesController < ApplicationController
    def new
      authorize(:count_fixes)
    end

    def create
      authorize(:count_fixes)
      CurrentUser.user.refresh_counts
      notice("Your counts will soon be refreshed")
      respond_to do |format|
        format.html { redirect_to(user_path(CurrentUser.user)) }
        format.json { head(:accepted) }
      end
    end
  end
end
