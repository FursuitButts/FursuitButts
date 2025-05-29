# frozen_string_literal: true

module Security
  class DashboardController < ApplicationController
    respond_to(:html)

    def index
      authorize(%i[security dashboard])
    end
  end
end
