# frozen_string_literal: true

module Tags
  class RelatedController < ApplicationController
    respond_to(:html, only: %i[show])
    respond_to(:json)

    def show
      @related_tags = authorize(RelatedTagQuery.new(query: params[:search][:query], category_id: params[:search][:category_id]))
      expires_in(30.seconds)
      respond_with(@related_tags)
    end

    def bulk
      @related_tags = authorize(BulkRelatedTagQuery.new(query: params[:query], category_id: params[:category_id]))
      respond_with(@related_tags) do |fmt|
        fmt.json do
          render(json: @related_tags.to_json)
        end
      end
    end
  end
end
