# frozen_string_literal: true

module FemboyFans
  class Configuration
    def version
      GitHelper.short_hash
    end

    def app_name
      "Femboy Fans"
    end

    def app_url
      "https://#{domain}"
    end

    def canonical_app_name
      app_name
    end

    def canonical_app_url
      app_url
    end

    def description
      "Your one-stop shop for femboy furries."
    end

    def domain
      "femboy.fan"
    end

    def cdn_domain
      "static.femboy.fan"
    end

    # Force rating:s on this version of the site.
    def safe_mode?
      false
    end

    def user_approvals_enabled?
      true
    end

    # The canonical hostname of the site.
    def hostname
      Socket.gethostname
    end

    # Contact email address of the admin.
    def contact_email
      "admin@#{domain}"
    end

    def takedown_email
      "admin@#{domain}"
    end

    def source_code_url
      "https://github.com/FemboyFans/FemboyFans"
    end

    # Stripped of any special characters.
    def safe_app_name
      app_name.gsub(/[^a-zA-Z0-9_-]/, "_")
    end

    # If enabled, users must verify their email addresses.
    def enable_email_verification?
      Rails.env.production?
    end

    def anonymous_user_name
      "Anonymous"
    end

    def anonymous_user
      user = User.new(name: anonymous_user_name, level: User::Levels::ANONYMOUS, created_at: Time.now)
      user.readonly!.freeze
      user
    end

    def system_user_name
      "System"
    end

    def system_user
      User.find_or_create_by!(name: system_user_name, level: User::Levels::SYSTEM) do |user|
        user.email                = "system@#{domain}"
        user.can_approve_posts    = true
        user.unrestricted_uploads = true
        user.email_verified       = true
      end
    end

    def default_user_timezone
      "Central Time (US & Canada)"
    end

    # The default name to use for anyone who isn't logged in.
    def default_guest_name
      "Anonymous"
    end

    # Set the default level, permissions, and other settings for new users here.
    def customize_new_user(user)
      user.blacklisted_tags           = default_blacklist.join("\n")
      user.comment_threshold          = -10
      user.enable_autocomplete        = true
      user.enable_keyboard_navigation = true
      user.per_page                   = records_per_page
      user.style_usernames            = true
      user.move_related_thumbnails    = true
      user.enable_hover_zoom          = true
      user.hover_zoom_shift           = true
      user.hover_zoom_sticky_shift    = true
      user.go_to_recent_forum_post    = true
      user.upload_notifications       = User.upload_notifications_options
      user.email_verified             = !enable_email_verification?
      user.level                      = User::Levels::RESTRICTED if user_approvals_enabled? && user.level == User::Levels::MEMBER
    end

    def default_blacklist
      []
    end

    def safeblocked_tags
      []
    end

    # This allows using statically linked copies of ffmpeg in non default locations. Not universally supported across
    # the codebase at this time.
    def ffmpeg_path
      "/usr/bin/ffmpeg"
    end

    # Thumbnail size
    def small_image_width
      300
    end

    # Large resize image width. Set to nil to disable.
    def large_image_width
      850
    end

    def large_image_prefix
      ""
    end

    def protected_path_prefix
      "deleted"
    end

    def protected_file_secret
      "abc123"
    end

    def replacement_path_prefix
      "replacements"
    end

    def replacement_file_secret
      "abc123"
    end

    def deleted_preview_url
      "/images/deleted-preview.png"
    end

    # When calculating statistics based on the posts table, gather this many posts to sample from.
    def post_sample_size
      300
    end

    # List of memcached servers
    def memcached_servers
      %w[127.0.0.1:11211]
    end

    def alias_implication_forum_category
      1
    end

    # After a post receives this many comments, new comments will no longer bump the post in comment/index.
    def comment_threshold
      40
    end

    def disable_throttles?
      false
    end

    def disable_age_checks?
      false
    end

    def disable_cache_store?
      false
    end

    # Members cannot post more than X comments in an hour.
    def member_comment_limit
      15
    end

    def comment_vote_limit
      25
    end

    def post_vote_limit
      1_000
    end

    def dmail_minute_limit
      2
    end

    def dmail_limit
      30
    end

    def dmail_day_limit
      60
    end

    def dmail_restricted_day_limit
      5
    end

    def tag_suggestion_limit
      15
    end

    def forum_vote_limit
      25
    end

    # Artists creator or edited in the last hour
    def artist_edit_limit
      25
    end

    # Wiki pages created or edited in the last hour
    def wiki_edit_limit
      60
    end

    # Notes applied to posts edited or created in the last hour
    def note_edit_limit
      50
    end

    # Pools created in the last hour
    def pool_limit
      2
    end

    # Pools created or edited in the last hour
    def pool_edit_limit
      10
    end

    # Pools that you can edit the posts for in the last hour
    def pool_post_edit_limit
      30
    end

    # Members cannot create more than X post versions in an hour.
    def post_edit_limit
      150
    end

    def post_appeal_limit
      5
    end

    def post_flag_limit
      20
    end

    # Flat limit that applies to all users, regardless of level
    def hourly_upload_limit
      30
    end

    def ticket_limit
      30
    end

    # Members cannot change the category of pools with more than this many posts.
    def pool_category_change_limit
      30
    end

    def post_replacement_per_day_limit
      2
    end

    def post_replacement_per_post_limit
      5
    end

    def compact_uploader_minimum_posts
      10
    end

    def remember_key
      "abc123"
    end

    def tag_type_change_cutoff(user)
      if user.is_trusted?
        1_000
      else
        100
      end
    end

    # Users cannot search for more than X regular tags at a time.
    def tag_query_limit
      40
    end

    def followed_tag_limit(user)
      if user.is_staff?
        1000
      elsif user.is_trusted?
        500
      else
        100
      end
    end

    # If the user can request a bulk update request containing a nuke instruction
    def can_bur_nuke?(user)
      user.is_admin?
    end

    def bur_entry_limit(user)
      return Float::INFINITY if user.is_admin?
      50
    end

    # Return true if the given tag shouldn't count against the user's tag search limit.
    def is_unlimited_tag?(tag)
      !!(tag =~ /\A(-?status:deleted|rating:s.*|limit:.+)\z/i)
    end

    # After this many pages, the paginator will switch to sequential mode.
    def max_numbered_pages
      1_000
    end

    def max_per_page
      500
    end

    def comment_max_size
      10_000
    end

    def dmail_max_size
      50_000
    end

    def forum_post_max_size
      50_000
    end

    def note_max_size
      1_000
    end

    def pool_descr_max_size
      10_000
    end

    def post_descr_max_size
      50_000
    end

    def ticket_max_size
      5_000
    end

    def user_about_max_size
      50_000
    end

    def blacklisted_tags_max_size
      150_000
    end

    def custom_style_max_size
      500_000
    end

    def wiki_page_max_size
      250_000
    end

    def user_feedback_max_size
      20_000
    end

    def news_update_max_size
      50_000
    end

    def pool_post_limit(_user)
      1_000
    end

    def set_post_limit(user) # rubocop:disable Naming/AccessorMethodName
      if user.is_admin?
        Float::INFINITY
      else
        10_000
      end
    end

    def disapproval_message_max_size
      250
    end

    def discord_site
    end

    def discord_secret
    end

    # Maximum size of an upload. If you change this, you must also change
    # `client_max_body_size` in your nginx.conf.
    def max_file_size
      100.megabytes
    end

    def max_file_sizes
      {
        "jpg"  => 100.megabytes,
        "png"  => 100.megabytes,
        "webp" => 100.megabytes,
        "gif"  => 20.megabytes,
        "webm" => 100.megabytes,
        "mp4"  => 100.megabytes,
      }
    end

    def max_apng_file_size
      20.megabytes
    end

    def max_mascot_file_sizes
      {
        "png"  => 1.megabyte,
        "jpg"  => 1.megabyte,
        "webp" => 1.megabyte,
      }
    end

    def max_mascot_width
      1000
    end

    def max_mascot_height
      1000
    end

    # Measured in seconds
    def max_video_duration
      3600
    end

    # Maximum resolution (width * height) of an upload. Default: 441 megapixels (21000x21000 pixels).
    def max_image_resolution
      15_000 * 15_000
    end

    # Maximum width of an upload.
    def max_image_width
      15_000
    end

    # Maximum height of an upload.
    def max_image_height
      15_000
    end

    def max_tags_per_post
      2000
    end

    # Permanently redirect all HTTP requests to HTTPS.
    #
    # https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
    # http://api.rubyonrails.org/classes/ActionDispatch/SSL.html
    def ssl_options
      {
        redirect: { exclude: ->(request) { request.subdomain == "insecure" } },
        hsts:     {
          expires:    1.year,
          preload:    true,
          subdomains: false,
        },
      }
    end

    # The method to use for storing image files.
    def storage_manager
      # Store files on the local filesystem.
      # base_dir - where to store files (default: under public/data)
      # base_url - where to serve files from (default: http://#{hostname}/data)
      # hierarchical: false - store files in a single directory
      # hierarchical: true - store files in a hierarchical directory structure, based on the MD5 hash
      StorageManager::Local.new(base_dir: Rails.public_path.join("data").to_s, hierarchical: true)
      # StorageManager::Ftp.new(ftp_hostname, ftp_port, ftp_username, ftp_password, base_dir: "", base_path: "", base_url: "https://static.femboy.fan", hierarchical: true)

      # Select the storage method based on the post's id and type (preview, large, or original).
      # StorageManager::Hybrid.new do |id, md5, file_ext, type|
      #   if type.in?([:large, :original]) && id.in?(0..850_000)
      #     StorageManager::Local.new(base_dir: "/path/to/files", hierarchical: true)
      #   else
      #     StorageManager::Local.new(base_dir: "/path/to/files", hierarchical: true)
      #   end
      # end
    end

    # The method to use for backing up image files.
    def backup_storage_manager
      # Don't perform any backups.
      StorageManager::Null.new

      # Backup files to /mnt/backup on the local filesystem.
      # StorageManager::Local.new(base_dir: "/mnt/backup", hierarchical: false)
    end

    def enable_signups?
      true
    end

    def enable_stale_forum_topics?
      true
    end

    def forum_topic_stale_window
      6.months
    end

    def forum_topic_aibur_stale_window
      1.year
    end

    def flag_reasons
      [
        {
          name:   "uploading_guidelines",
          reason: "Does not meet the \"uploading guidelines\":/help/uploading_guidelines",
          text:   "This post fails to meet the site's standards, be it for artistic worth, image quality, relevancy, or something else.\nKeep in mind that your personal preferences have no bearing on this. If you find the content of a post objectionable, simply \"blacklist\":/help/blacklisting it.",
        },
        {
          name:   "dnp_artist",
          reason: "The artist of this post is on the \"avoid posting list\":/static/avoid_posting",
          text:   "Certain artists have requested that their work is not to be published on this site, and were granted [[avoid_posting|Do Not Post]] status.\nSometimes, that status comes with conditions; see [[conditional_dnp]] for more information",
        },
        {
          name:   "pay_content",
          reason: "Paysite, commercial, or subscription content",
          text:   "We do not host paysite or commercial that is under 2 years old.",
        },
        {
          name:   "trace",
          reason: "Trace of another artist's work",
          text:   "Images traced from other artists' artwork are not accepted on this site. Referencing from something is fine, but outright copying someone else's work is not.\nPlease, leave more information in the comments, or simply add the original artwork as the posts's parent if it's hosted on this site.",
        },
        {
          name:   "previously_deleted",
          reason: "Previously deleted",
          text:   "Posts usually get removed for a good reason, and reuploading of deleted content is not acceptable.\nPlease, leave more information in the comments, or simply add the original post as this post's parent.",
        },
        {
          name:   "real_porn",
          reason: "Real-life pornography",
          text:   "Posts featuring real-life pornography are not acceptable on this site.",
        },
        {
          name:   "corrupt",
          reason: "File is either corrupted, broken, or otherwise does not work",
          text:   "Something about this post does not work quite right. This may be a broken video, or a corrupted image.\nEither way, in order to avoid confusion, please explain the situation in the comments.",
        },
        {
          name:   "inferior",
          reason: "Duplicate or inferior version of another post",
          text:   "A superior version of this post already exists on the site.\nThis may include images with better visual quality (larger, less compressed), but may also feature \"fixed\" versions, with visual mistakes accounted for by the artist.\nNote that edits and alternate versions do not fall under this category.",
          parent: true,
        },
      ]
    end

    # Any custom code you want to insert into the default layout without
    # having to modify the templates.
    def custom_html_header_content
      nil
    end

    def flag_notice_wiki_page
      "internal:flag_notice"
    end

    def replacement_notice_wiki_page
      "internal:replacement_notice"
    end

    def avoid_posting_notice_wiki_page
      "internal:avoid_posting_notice"
    end

    def discord_notice_wiki_page
      "internal:discord_notice"
    end

    def rules_body_wiki_page
      "internal:rules_body"
    end
    
    def restricted_notice_wiki_page
      "internal:restricted_notice"
    end

    def appeal_notice_wiki_page
      "internal:appeal_notice"
    end

    def ban_notice_wiki_page
      "internal:ban_notice"
    end

    # The number of posts displayed per page.
    def records_per_page
      100
    end

    def can_user_see_post?(user, post)
      # TODO: appealed posts should be visible, but this makes it far too easy to get the contents of deleted posts at a moments notice
      return true if user.is_janitor? # || post.is_appealed?
      !post.is_deleted?
    end

    def user_needs_login_for_post?(_post)
      false
    end

    def select_posts_visible_to_user(user, posts)
      posts.select { |x| can_user_see_post?(user, x) }
    end

    def enable_autotagging?
      true
    end

    # tags excluded when listing artists
    def artist_exclusion_tags
      %w[avoid_posting conditional_dnp epilepsy_warning sound_warning]
    end

    # The default headers to be sent with outgoing http requests. Some external
    # services will fail if you don't set a valid User-Agent.
    def http_headers
      {
        user_agent: "#{safe_app_name}/#{version} (https://github.com/FemboyFans/FemboyFans)",
      }
    end

    # https://lostisland.github.io/faraday/#/customization/connection-options
    def faraday_options
      {
        request: {
          timeout:      10,
          open_timeout: 10,
        },
        headers: http_headers,
      }
    end

    # you should override this
    def email_key
      "zDMSATq0W3hmA5p3rKTgD"
    end

    def mailgun_api_key
    end

    def mailgun_domain
    end

    def mail_from_addr
      "noreply@localhost"
    end

    def smtp_address
    end

    def smtp_port
    end

    def smtp_domain
    end

    def smtp_username
    end

    def smtp_password
    end

    def smtp_authentication
    end

    def smtp_tls
    end

    # disable this for tests
    def enable_sock_puppet_validation?
      !Rails.env.development?
    end

    def recommender_server
    end

    def iqdb_server
    end

    def opensearch_host
    end

    # Use a recaptcha on the signup page to protect against spambots creating new accounts.
    # https://developers.google.com/recaptcha/intro
    def enable_recaptcha?
      Rails.env.production? && FemboyFans.config.recaptcha_site_key.present? && FemboyFans.config.recaptcha_secret_key.present?
    end

    def recaptcha_site_key
    end

    def recaptcha_secret_key
    end

    def enable_image_cropping?
      true
    end

    def redis_url
    end

    def bypass_upload_whitelist?(user)
      user.is_admin? || user == User.system
    end

    # Additional video samples will be generated in these dimensions if it makes sense to do so
    # They will be available as additional scale options on applicable posts in the order they appear here
    def video_rescales
      { "720p" => [1280, 720], "480p" => [640, 480] }
    end

    def image_rescales
      []
    end

    def janitor_reports_discord_webhook_url
      nil
    end

    def moderator_stats_discord_webhook_url
      nil
    end

    def aibur_stats_discord_webhook_url
      nil
    end

    def ftp_hostname
    end

    def ftp_port
    end

    def ftp_username
    end

    def ftp_password
    end

    def bunny_secret_token
    end

    def ticket_quick_response_buttons
      [
        { name: "Handled", text: "Handled, thank you." },
        { name: "Reviewed", text: "Reviewed, thank you." },
        { name: "NAT", text: "Reviewed, no action taken." },
        { name: "Closed", text: "Ticket closed." },
        { name: "Dismissed", text: "Ticket dismissed." },
        { name: "Old", text: "That comment is from N years ago.\nWe do not punish people for comments older than 3 months." },
        { name: "Reply", text: "I believe that you tried to reply to a comment, but reported it instead.\nPlease, be more careful in the future." },
        { name: "Already", text: "User already received a record for that message." },
        { name: "Banned", text: "This user is already banned." },
        { name: "Blacklist", text: "If you find the contents of that post objectionable, \"blacklist\":/help/blacklisting it." },
        { name: "Takedown", text: "Artists and character owners may request a takedown \"here\":/static/takedown.\nWe do not accept third party takedowns." },
      ]
    end

    def reports_enabled?
      FemboyFans.config.reports_server.present?
    end

    def reports_server
    end

    def reports_server_internal
      FemboyFans.config.reports_server
    end

    def report_key
    end

    def rakismet_key
    end

    def rakismet_url
      "https://#{hostname}"
    end

    def default_forum_category
      alias_implication_forum_category
    end

    def upload_whitelists_topic
      0
    end

    def show_tag_scripting?(user)
      user.is_trusted?
    end

    def show_backtrace?(user, _backtrace)
      return true if Rails.env.development?
      user.is_janitor?
    end

    # only applies to approving
    def tag_change_request_update_limit(user)
      return 0 unless user.can_manage_aibur?
      if user.is_trusted?
        100
      elsif user.is_janitor?
        500
      elsif user.is_moderator?
        1_000
      elsif user.is_admin?
        100_000
      elsif user.is_owner?
        Float::INFINITY
      else
        0
      end
    end

    def alias_category_change_cutoff
      10_000
    end
  end

  class EnvironmentConfiguration
    def custom_configuration
      @custom_configuration ||= CustomConfiguration.new
    end

    def env_to_boolean(method, var)
      is_boolean = method.to_s.end_with?("?")
      return true if is_boolean && var.truthy?
      return false if is_boolean && var.falsy?
      var
    end

    def method_missing(method, *)
      var = ENV.fetch("FEMBOYFANS_#{method.to_s.upcase.chomp('?')}", nil)

      if var.present?
        env_to_boolean(method, var)
      else
        custom_configuration.send(method, *)
      end
    end
  end

  def config
    @config ||= EnvironmentConfiguration.new
  end

  module_function :config
end
