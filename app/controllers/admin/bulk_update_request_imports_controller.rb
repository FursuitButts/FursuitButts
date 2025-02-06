# frozen_string_literal: true

module Admin
  class BulkUpdateRequestImportsController < ApplicationController
    def new
      authorize(BulkUpdateRequestImporter)
    end

    def create
      bparams = params[:batch].presence || params
      @importer = authorize(BulkUpdateRequestImporter.new(bparams[:script], bparams[:forum_id]))
      @importer.validate!(CurrentUser.user)
      begin
        BulkUpdateRequest.transaction { @importer.process! }
      rescue BulkUpdateRequestImporter::Error => e
        @error = e
        notice("Import failed")
        respond_to do |format|
          format.html { render(:new) }
          format.json { render_expected_error(400, e.message) }
        end
        return
      end
      notice("Import queued")
      respond_to do |format|
        format.html { redirect_to(new_admin_bulk_update_request_import_path) }
        format.json
      end
    end
  end
end
