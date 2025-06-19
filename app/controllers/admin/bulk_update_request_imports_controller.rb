# frozen_string_literal: true

module Admin
  class BulkUpdateRequestImportsController < ApplicationController
    def new
      authorize(BulkUpdateRequestImport)
    end

    def create
      bparams = params[:batch].presence || params
      @importer = authorize(BulkUpdateRequestImport.new(bparams[:script], bparams[:forum_id], CurrentUser.user, CurrentUser.ip_addr))
      @importer.validate!
      @importer.queue

      notice("Import queued")
      respond_to do |format|
        format.html { redirect_to(new_admin_bulk_update_request_import_path) }
        format.json
      end
    rescue ActiveModel::ValidationError, BulkUpdateRequestProcessor::Error, BulkUpdateRequestCommands::ProcessingError => e
      @error = e
      notice("Import failed")
      respond_to do |format|
        format.html { render(:new, status: 400) }
        format.json { render_expected_error(400, e.message) }
      end
    end
  end
end
