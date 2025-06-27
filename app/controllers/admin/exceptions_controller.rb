# frozen_string_literal: true

module Admin
  class ExceptionsController < ApplicationController
    def index
      @exception_logs = authorize(ExceptionLog).search_current(search_params(ExceptionLog))
                                               .paginate(params[:page], limit: 100)
    end

    def show
      if params[:id] =~ /\A\d+\z/
        @exception_log = ExceptionLog.find(params[:id])
      else
        @exception_log = ExceptionLog.find_by!(code: params[:id])
      end
      authorize(@exception_log)
    end
  end
end
