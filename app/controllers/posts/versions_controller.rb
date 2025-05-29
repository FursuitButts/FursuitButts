# frozen_string_literal: true

module Posts
  class VersionsController < ApplicationController
    respond_to(:html, :json)
    respond_to(:js, only: %i[undo])

    def index
      @post_versions = PostVersion.search(search_params).paginate(params[:page], limit: params[:limit], max_count: 10_000, includes: [:updater, { post: [:versions] }])
      respond_with(@post_versions)
    end

    def undo
      can_edit = CurrentUser.can_post_edit_with_reason
      raise(User::PrivilegeError, "Updater #{User.throttle_reason(can_edit)}") unless can_edit == true

      @post_version = PostVersion.find(params[:id])
      @post_version.undo!
    end
  end
end
