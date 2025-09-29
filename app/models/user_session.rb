# frozen_string_literal: true

class UserSession < ApplicationRecord
  module SearchMethods
    def query_dsl
      super
        .field(:session_id)
        .field(:user_agent)
        .field(:ip_addr)
    end
  end
end
