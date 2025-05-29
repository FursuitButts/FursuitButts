# frozen_string_literal: true

module Moderator
  class IpAddrsController < ApplicationController
    respond_to(:html, :json)

    def index
      search = authorize(IpAddrSearch).new(search_params(IpAddrSearch))
      @results = search.execute
      respond_with(@results)
    end

    def export
      search = authorize(IpAddrSearch).new(search_params(IpAddrSearch).merge({ with_history: true }))
      @results = search.execute
      respond_with(@results) do |format|
        format.json do
          render(json: @results.is_a?(Array) ? @results : @results[:ip_addrs].uniq)
        end
      end
    end
  end
end
