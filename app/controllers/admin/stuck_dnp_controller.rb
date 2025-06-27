# frozen_string_literal: true

module Admin
  class StuckDnpController < ApplicationController
    wrap_parameters(:stuck_dnp)

    def new
      authorize(:stuck_dnp)
    end

    def create
      authorize(:stuck_dnp)
      query = permitted_attributes(:stuck_dnp)[:query]

      if query.blank?
        flash[:notice] = "No query specified"
        redirect_to(new_admin_stuck_dnp_path)
        return
      end

      dnp_tags = %w[avoid_posting conditional_dnp]
      post_ids = []
      Post.tag_match_system("#{query} ~avoid_posting ~conditional_dnp").limit(1000).each do |p|
        previous_tags = p.fetch_tags(*dnp_tags)

        p.automated_edit = true

        locked_tags = TagQuery.scan((p.locked_tags || "").downcase)
        locked_tags -= dnp_tags
        p.locked_tags = locked_tags.join(" ")
        p.remove_tag(dnp_tags)

        p.save

        if previous_tags != p.fetch_tags(*dnp_tags)
          post_ids << p.id
        end
      end

      StaffAuditLog.log!(CurrentUser.user, :stuck_dnp, query: query, post_ids: post_ids)
      flash[:notice] = "DNP tags removed from #{post_ids.count} posts"
      redirect_to(new_admin_stuck_dnp_path)
    end
  end
end
