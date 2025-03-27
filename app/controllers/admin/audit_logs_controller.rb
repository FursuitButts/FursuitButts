# frozen_string_literal: true

module Admin
  class AuditLogsController < ApplicationController
    respond_to :html, :json

    def index
      @audit_logs = authorize(StaffAuditLog).html_includes(request, :user)
                                            .search(search_params(StaffAuditLog))
                                            .paginate(params[:page], limit: params[:limit])
      respond_with(@audit_logs)
    end
  end
end
