# frozen_string_literal: true

module Sources
  module Alternates
    def self.all
      constants.map { |name| const_get(name) }.select { |klass| klass < Base }
    end

    def self.find(url, default: Alternates::Null)
      alternate = all.map { |alt| alt.new(url) }.detect(&:match?)
      alternate || default&.new(url)
    end
  end
end
