# frozen_string_literal: true

# TODO: rewrite this script to integrate with new upstream script
require "digest/md5"
require "tempfile"
require "net/http"
require_relative "seeds/post_deletion_reasons"
require_relative "seeds/post_replacement_rejection_reasons"
require_relative "seeds/posts"

# Uncomment to see detailed logs
# ActiveRecord::Base.logger = ActiveSupport::Logger.new($stdout)

module Seeds
  def self.run!
    CurrentUser.user = User.system
    Seeds::Posts.run!
    Mascots.run!
  end

  def self.create_aibur_category!
    ForumCategory.find_or_create_by!(name: "Tag Alias and Implication Suggestions") do |category|
      category.can_view = 0
    end
  end

  def self.api_request(path)
    puts("-> GET #{base_url}#{path}")
    response = Faraday.get("#{base_url}#{path}", nil, user_agent: "femboyfans/seeding")
    JSON.parse(response.body)
  end

  def self.base_url
    read_resources["base_url"]
  end

  def self.read_resources
    if @resources
      yield(@resources) if block_given?
      return @resources
    end
    @resources = YAML.load_file(Rails.root.join("db/seeds.yml"))
    @resources["tags"] << "randseed:#{Digest::MD5.hexdigest(Time.now.to_s)}" if @resources["tags"]&.include?("order:random")
    yield(@resources) if block_given?
    @resources
  end

  def self.log(...)
    puts(...)
  end

  module Mascots
    def self.run!
      Seeds.read_resources do |resources|
        if resources["mascots"].empty?
          create_from_web
        else
          create_from_local
        end
      end
    end

    def self.create_from_web
      Seeds.api_request("/mascots.json").each do |mascot|
        next if ::Mascot.exists?(display_name: mascot["display_name"])
        puts(mascot["url_path"])
        Mascot.find_or_create_by!(display_name: mascot["display_name"]) do |masc|
          masc.mascot_file = Downloads::File.new(mascot["url_path"]).download!
          masc.background_color = mascot["background_color"]
          masc.artist_url = mascot["artist_url"]
          masc.artist_name = mascot["artist_name"]
          masc.available_on_string = FemboyFans.config.app_name
          masc.hide_anonymous = mascot["hide_anonymous"]
          masc.active = mascot["active"]
        end
      end
    end

    def self.create_from_local
      resources = Seeds.read_resources
      resources["mascots"].each do |mascot|
        next if ::Mascot.exists?(display_name: mascot["name"])
        puts(mascot["file"])
        Mascot.find_or_create_by!(display_name: mascot["name"]) do |masc|
          masc.mascot_file = Downloads::File.new(mascot["file"]).download!
          masc.background_color = mascot["color"]
          masc.artist_url = mascot["artist_url"]
          masc.artist_name = mascot["artist_name"]
          masc.available_on_string = FemboyFans.config.app_name
          masc.active = mascot["active"]
          masc.hide_anonymous = mascot["hide_anonymous"]
        end
      end
    end
  end
end

if ENV["POSTS_ONLY"] == "1"
  CurrentUser.as_system { Seeds::Posts.run! }
else
  CurrentUser.as_system do
    ModAction.without_logging do
      Seeds.create_aibur_category!
      PostDeletionReasons.run!
      PostReplacementRejectionReasons.run!

      unless Rails.env.test?
        Seeds.run!
      end
    end
  end
end
