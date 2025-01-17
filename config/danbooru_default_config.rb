require 'socket'

module Danbooru
  class Configuration
    # The version of this Danbooru.
    def version
      "1.0.0"
    end

    # The name of this Danbooru.
    def app_name
      "Fuzzy Butt Central"
    end

    def description
      "The best fuzzy butts on the net."
    end

    def domain
      "fursuitbutts.com"
    end

    # Force rating:s on this version of the site.
    def safe_mode?
      false
    end

    # The canonical hostname of the site.
    def hostname
      Rails.env.production? ? "fursuitbutts.com" : "fursuitbutts.local"
    end

    # The list of all domain names this site is accessible under.
    # Example: %w[danbooru.donmai.us sonohara.donmai.us hijiribe.donmai.us safebooru.donmai.us]
    def hostnames
      [hostname]
    end

    # Contact email address of the admin.
    def contact_email
      "fursuitbutts@yiff.rocks"
    end

    def takedown_email
      "none@fursuitbutts.local"
    end

    def takedown_links
      []
    end

    # System actions, such as sending automated dmails, will be performed with
    # this account. This account must have Moderator privileges.
    #
    # Run `rake db:seed` to create this account if it doesn't already exist in your install.
    def admin_user
      "Donovan_DMC"
    end

    def system_user
      "system"
    end

    def source_code_url
      "https://github.com/FursuitButts/FursuitButts"
    end

    def commit_url(hash)
      "#{source_code_url}/commit/#{hash}"
    end

    def releases_url
      "#{source_code_url}/releases"
    end

    def issues_url
      "#{source_code_url}/issues"
    end

    # Stripped of any special characters.
    def safe_app_name
      app_name.gsub(/[^a-zA-Z0-9_-]/, "_")
    end

    # The default name to use for anyone who isn't logged in.
    def default_guest_name
      "Anonymous"
    end

    def levels
      {
          "Anonymous" => 0,
          "Blocked" => 10,
          "Member" => 20,
          "Privileged" => 30,
          "Curator" => 31,
          "Former Staff" => 32,
          "Janitor" => 33,
          "System" => 34,
          "Moderator" => 40,
          "Admin" => 50
      }
    end

    # Set the default level, permissions, and other settings for new users here.
    def customize_new_user(user)
      user.comment_threshold = -10 unless user.will_save_change_to_comment_threshold?
      user.blacklisted_tags = ""
      user.level = User::Levels::MEMBER
      true
    end

    # This allows using statically linked copies of ffmpeg in non default locations. Not universally supported across
    # the codebase at this time.
    def ffmpeg_path
      "/usr/bin/ffmpeg"
    end

    # Thumbnail size
    def small_image_width
      150
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
    end

    def replacement_path_prefix
      "replacements"
    end

    def replacement_file_secret
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
    end

    def alias_implication_forum_category
      1
    end

    # After a post receives this many comments, new comments will no longer bump the post in comment/index.
    def comment_threshold
      40
    end

    def disable_throttles?
    end

    def disable_age_checks?
      false
    end

    def disable_cache_store?
      false
    end

    def takedown_email_max_len
      250
    end

    def takedown_reason_max_len
      5_000
    end

    def takedown_instructions_max_len
      5_000
    end

    def takedown_notes_max_len
      5_000
    end

    def takedown_max_posts
      5_000
    end

    # Members cannot post more than X comments in an hour.
    def member_comment_limit
      15
    end

    def comment_vote_limit
      10
    end

    def comment_threshold_max
      50_000
    end

    def comment_threshold_min
      -50_000
    end

    def post_vote_limit
      3_000
    end

    def dmail_limit
      20
    end

    def dmail_minute_limit
      1
    end

    def dmail_maximum_words
      1_000
    end

    def dmail_title_max_len
      250
    end

    def dmail_autoban_threshold
      10
    end

    def dmail_autoban_window
      24.hours
    end

    def dmail_autoban_duration
      3
    end

    def tag_suggestion_limit
      15
    end

    def forum_vote_limit
      50
    end

    # Blips created in the last hour
    def blip_limit
      25
    end

    # Artists creator or edited in the last hour
    def artist_edit_limit
      25
    end

    def artist_group_name_minimum
      100
    end

    def max_urls_per_artist
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

    def post_flag_limit
      10
    end

    # Flat limit that applies to all users, regardless of level
    def hourly_upload_limit
      30
    end

    def replace_post_limit
      10
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

    def remember_key
    end

    def tag_type_change_cutoff
      100
    end

    def tag_max_len
      100
    end

    def compact_uploader_threshold
      10
    end

    def blacklisted_tags_max_len
      150_000
    end

    def custom_style_max_len
      500_000
    end

    def name_max_len
      20
    end

    def display_name_max_len
      20
    end

    def favorite_limit(user)
      if user.is_curator?
        250_000
      elsif user.is_privileged?
        125_000
      else
        80_000
      end
    end

    def api_regen_multiplier(user)
      1
    end

    def api_burst_limit(user)
      # can make this many api calls at once before being bound by
      # api_regen_multiplier refilling your pool
      if user.is_curator?
        120
      elsif user.is_privileged?
        90
      else
        60
      end
    end

    def statement_timeout(user)
      if user.is_curator?
        9_000
      elsif user.is_privileged?
        6_000
      else
        3_000
      end
    end

    # Determines who can see ads.
    def can_see_ads?(user)
      !user.is_privileged?
    end

    # Users cannot search for more than X regular tags at a time.
    def base_tag_query_limit
      20
    end

    def tag_query_limit
      if CurrentUser.user.present?
        CurrentUser.user.tag_query_limit
      else
        base_tag_query_limit
      end
    end

    def tag_query_limit2(user)
      40
    end

    # Return true if the given tag shouldn't count against the user's tag search limit.
    def is_unlimited_tag?(tag)
      !!(tag =~ /\A(-?status:deleted|rating:s.*|limit:.+)\z/i)
    end

    # After this many pages, the paginator will switch to sequential mode.
    def max_numbered_pages
      750
    end

    def blip_max_size
      1_000
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

    def forum_post_title_max_len
      250
    end

    def note_max_size
      1_000
    end

    def pool_description_max_len
      10_000
    end

    def pool_name_max_len
      250
    end

    def pool_max_posts
      1_000
    end

    def post_description_max_len
      50_000
    end

    def ticket_max_size
      5_000
    end

    def user_about_max_size
      50_000
    end

    def wiki_page_title_max_len
      100
    end

    def wiki_page_max_size
      250_000
    end

    def post_set_max_maintainers
      75
    end

    def post_set_name_max_len
      100
    end

    def post_set_shortname_max_len
      50
    end

    def post_set_maximum_owned
      75
    end

    def post_set_max_posts
      10_000
    end

    def beta_notice?
      false
    end

    def discord_site
      "https://discord.gg/CKEyjSJwcM"
    end

    # Maximum size of an upload. If you change this, you must also change
    # `client_max_body_size` in your nginx.conf.
    def max_file_size
      50.megabytes
    end

    def min_file_size
      16
    end

    def max_file_sizes
      # TODO: increase max file sizes when we get more storage
      {
          'jpg' => 40.megabytes,
          'gif' => 20.megabytes,
          'png' => 40.megabytes,
          'swf' => 0,
          'webm' => 50.megabytes,
          'mp4' => 50.megabytes,
          'zip' => 0
      }
    end

    def max_apng_file_size
      20.megabytes
    end

    # Measured in seconds
    def max_video_duration
      3600
    end

    # Maximum resolution (width * height) of an upload. Default: 441 megapixels (21000x21000 pixels).
    def max_image_resolution
      15000 * 15000
    end

    # Maximum width of an upload.
    def max_image_width
      15000
    end

    # Maximum height of an upload.
    def max_image_height
      15000
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
        hsts: {
          expires: 1.year,
          preload: true,
          subdomains: false,
        },
      }
    end

    # Disable the forced use of HTTPS.
    # def ssl_options
    #   false
    # end

    # The name of the server the app is hosted on.
    def server_host
      Socket.gethostname
    end

    # Names of all Danbooru servers which serve out of the same common database.
    # Used in conjunction with load balancing to distribute files from one server to
    # the others. This should match whatever gethostname returns on the other servers.
    def all_server_hosts
      [server_host]
    end

    # Names of other Danbooru servers.
    def other_server_hosts
      @other_server_hosts ||= all_server_hosts.reject {|x| x == server_host}
    end

    def remote_server_login
      "danbooru"
    end

    def archive_server_login
      "danbooru"
    end

    def s3_access_key_id
    end

    def s3_secret_access_key
    end

    def s3_bucket
      "fursuitbutts"
    end

    def s3_protected_bucket
      "fursuitbutts-protected"
    end

    # The method to use for storing image files.
    def storage_manager
     if Rails.env.production?
        StorageManager::S3.new(Danbooru.config.s3_bucket, hierarchical: true, base_url: "https://butts.yiff.media/", s3_options: {
          credentials: Aws::Credentials.new(Danbooru.config.s3_access_key_id, Danbooru.config.s3_secret_access_key),
          region: "us-central-1",
          endpoint: "https://s3.us-central-1.wasabisys.com"
        })
    else
        StorageManager::Local.new(base_url: "https://fursuitbutts.local/data/", base_dir: "#{Rails.root}/public/data", hierarchical: true)
     end
    end

    def backup_storage_manager
      StorageManager::Null.new

      # Backup files to /mnt/backup on the local filesystem.
      # StorageManager::Local.new(base_dir: "/mnt/backup", hierarchical: false)

      # Backup files to /mnt/backup on a remote system. Configure SSH settings
      # in ~/.ssh_config or in the ssh_options param (ref: http://net-ssh.github.io/net-ssh/Net/SSH.html#method-c-start)
      # StorageManager::SFTP.new("www.example.com", base_dir: "/mnt/backup", ssh_options: {})

      # Backup files to an S3 bucket. The bucket must already exist and be
      # writable by you. Configure your S3 settings in aws_region and
      # aws_credentials below, or in the s3_options param (ref:
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/S3/Client.html#initialize-instance_method)
      # StorageManager::S3.new("my_s3_bucket_name", s3_options: {})
    end

#TAG CONFIGURATION

    #Full tag configuration info for all tags
    def full_tag_config_info
      @full_tag_category_mapping ||= {
        "general" => {
          "category" => 0,
          "short" => "gen",
          "extra" => [],
          "header" => 'General',
          "humanized" => nil,
          "mod_only" => false,
          "relatedbutton" => "General",
          "css" => {
            "color" => "$link_color",
            "hover" => "$link_hover_color"
          }
        },
        "species" => {
          "category" => 5,
          "short" => "spec",
          "extra" => [],
          "header" => 'Species',
          "humanized" => nil,
          "mod_only" => false,
          "relatedbutton" => "Species",
          "css" => {
            "color" => "#0F0",
            "hover" => "#070"
          }
        },
        "character" => {
          "category" => 4,
          "short" => "char",
          "extra" => ["ch"],
          "header" => 'Characters',
          "humanized" => {
            "slice" => 5,
            "exclusion" => [],
            "regexmap" => /^(.+?)(?:_\(.+\))?$/,
            "formatstr" => "%s"
          },
          "mod_only" => false,
          "relatedbutton" => "Characters",
          "css" => {
            "color" => "#0A0",
            "hover" => "#6B6"
          }
        },
        "copyright" => {
          "category" => 3,
          "short" => "copy",
          "extra" => ["co"],
          "header" => 'Copyrights',
          "humanized" => {
            "slice" => 1,
            "exclusion" => [],
            "regexmap" => //,
            "formatstr" => "(%s)"
          },
          "mod_only" => false,
          "relatedbutton" => "Copyrights",
          "css" => {
            "color" => "#A0A",
            "hover" => "#B6B"
          }
        },
        "artist" => {
          "category" => 1,
          "short" => "art",
          "extra" => [],
          "header" => 'Artists',
          "humanized" => {
            "slice" => 0,
            "exclusion" => %w(avoid_posting conditional_dnp),
            "regexmap" => //,
            "formatstr" => "created by %s"
          },
          "mod_only" => false,
          "relatedbutton" => "Artists",
          "css" => {
            "color" => "#A00",
            "hover" => "#B66"
          }
        },
        "invalid" => {
          "category" => 6,
          "short" => "inv",
          "extra" => [],
          "header" => 'Invalid',
          "humanized" => nil,
          "mod_only" => true,
          "relatedbutton" => nil,
          "css" => {
            "color" => "#000",
            "hover" => "#444"
          }
        },
        "lore" => {
          "category" => 8,
          "short" => 'lor',
          'extra' => [],
          'header' => 'Lore',
          'humanized' => nil,
          'mod_only' => true,
          'relatedbutton' => nil,
          'css' => {
              'color' => '#000',
              'hover' => '#444'
          }
        },
        "meta" => {
          "category" => 7,
          "short" => "meta",
          "extra" => [],
          "header" => 'Meta',
          "humanized" => nil,
          "mod_only" => true,
          "relatedbutton" => nil,
          "css" => {
            "color" => "#F80",
            "hover" => "#FA6"
          }
        }
      }
    end

#TAG ORDERS

    #Sets the order of the humanized essential tag string (models/post.rb)
    def humanized_tag_category_list
      @humanized_tag_category_list ||= ["character","copyright","artist"]
    end

    #Sets the order of the split tag header list (presenters/tag_set_presenter.rb)
    def split_tag_header_list
      @split_tag_header_list ||= ["invalid","artist","copyright","character","species","general","meta","lore"]
    end

    #Sets the order of the categorized tag string (presenters/post_presenter.rb)
    def categorized_tag_list
      @categorized_tag_list ||= ["invalid","artist","copyright","character","species","meta","general","lore"]
    end

    #Sets the order of the related tag buttons (javascripts/related_tag.js)
    def related_tag_button_list
      @related_tag_button_list ||= ["general","artist","species","character","copyright"]
    end

#END TAG

    # If enabled, users must verify their email addresses.
    def enable_email_verification?
      Rails.env.production?
    end

    def enable_signups?
      true
    end

    def flag_reasons
      [
          {
            name: 'dnp_artist',
            reason: "The artist of this post is on the [[avoid_posting|avoid posting list]]",
            text: "Certain artists have requested that their work is not to be published on this site, and were granted [[avoid_posting|Do Not Post]] status.\nSometimes, that status comes with conditions; see [[conditional_dnp]] for more information"
          },
          {
            name: 'pay_content',
            reason: "Paysite, commercial, or subscription content",
            text: "We do not host paysite or commercial content of any kind. This includes Patreon leaks, reposts from piracy websites, and so on."
          },
          {
            name: 'previously_deleted',
            reason: "Previously deleted",
            text: "Posts usually get removed for a good reason, and reuploading of deleted content is not acceptable.\nPlease, leave more information in the comments, or simply add the original post as this post's parent."
          },
          {
            name: 'corrupt',
            reason: "File is either corrupted, broken, or otherwise does not work",
            text: "Something about this post does not work quite right. This may be a broken video, or a corrupted image.\nEither way, in order to avoid confusion, please explain the situation in the comments."
          },
          {
            name: 'inferior',
            reason: "Duplicate or inferior version of another post",
            text: "A superior version of this post already exists on the site.\nThis may include images with better visual quality (larger, less compressed), but may also feature \"fixed\" versions, with visual mistakes accounted for by the artist.\nNote that edits and alternate versions do not fall under this category.",
            parent: true
          },
      ]
    end

    def flag_reason_48hours
      "If you are the artist, and want this image to be taken down [b]permanently[/b], file a \"takedown\":/static/takedown instead.\nTo replace the image with a \"fixed\" version, upload that image first, and then use the \"Duplicate or inferior version\" reason above.\nFor accidentally released paysite or private content, use the \"Paysite, commercial, or private content\" reason above."
    end

    def deletion_reasons
      [
        "Inferior version/duplicate of post #%PARENT_ID%",
        "Previously deleted (post #%PARENT_ID%)",
        "Excessive same base image set",
        "Colored base",
        "",
        "Does not meet minimum quality standards (Artistic)",
        "Does not meet minimum quality standards (Resolution)",
        "Does not meet minimum quality standards (Compression)",
        "Does not meet minimum quality standards (Low quality/effort edit)",
        "Does not meet minimum quality standards (Bad digitization of traditional media)",
        "Does not meet minimum quality standards (Photo)",
        "Does not meet minimum quality standards (%OTHER_ID%)",
        "Broken/corrupted file",
        "JPG resaved as PNG",
        "",
        "Irrelevant to site (Screencap)",
        "Irrelevant to site (Zero pictured)",
        "Irrelevant to site (%OTHER_ID%)",
        "",
        "Paysite/commercial content",
        "Traced artwork",
        "Traced artwork (post #%PARENT_ID%)",
        "Takedown #%OTHER_ID%",
        "The artist of this post is on the [[avoid_posting|avoid posting list]]",
        "[[conditional_dnp|Conditional DNP]] (Only the artist is allowed to post)",
        "[[conditional_dnp|Conditional DNP]] (%OTHER_ID%)",
      ]
    end

    def twitter_handle
      "FursuitButtsRev"
    end

    # Any custom code you want to insert into the default layout without
    # having to modify the templates.
    def custom_html_header_content
      %{
	      <meta name="description" content="#{description}">
        <!--Twitter-->
        <meta name="twitter:card" content="summary">
        <meta name="twitter:site" content="@#{twitter_handle}">
        <meta name="twitter:creator" content="@Donovan_DMC">
        <meta name="twitter:title" content="#{app_name}">
        <meta name="twitter:description" content="#{description}">
        <meta name="twitter:image" content="/images/mascots/strobes/3Full.jpeg">
        <meta name="Twitter:image:alt" content="#{app_name}'s' Logo">

        <!--Browser Caching-->
        <meta http-equiv="Cache-control" content="public">

        <!--Dublin Core - DC-->
        <meta name="DC.Title" lang="en" content="#{app_name}">
        <meta name="DC.Creator" lang="en" content="#{twitter_handle}">
        <meta name="DC.Subject" lang="en" content="Information">
        <meta name="DC.Description" lang="en" content="#{description}">
        <meta name="DC.Publisher" lang="en" content="#{twitter_handle}">
        <meta name="DC.Contributor" lang="en" content="Self">
        <meta name="DC.Date" lang="en" content="#{Time.now.year}">
        <meta name="DC.Type" lang="en" content="text">
        <meta name="DC.Format" lang="en" content="text/html">
        <meta name="DC.Language" lang="en" content="en-US">
        <meta name="DC.Rights" lang="en" content="All members can access">
        <link rel="schema.DC" lang="en" href="http://purl.org/dc/elements/1.1/">
        <link rel="schema.DCTERMS" lang="en" href="http://purl.org/dc/terms/">

        <!--Open Graph-->
        <meta property="og:title" content="#{app_name}">
        <meta property="og:site_name" content="#{app_name}">
        <meta property="og:description" content="#{description}">
        <meta property="og:url" content="https://#{hostname}">
        <meta property="og:type" content="website">
        <meta property="og:image" content="/images/mascots/strobes/3Full.jpeg">
        <meta property="og:image:secure_url" content="/images/mascots/strobes/3Full.jpeg">
        <meta property="og:image:type" content="image/jpeg">
        <meta property="og:image:width" content="640">
        <meta property="og:image:height" content="640">
        <meta property="og:image:alt" content="#{app_name}'s Icon'">
      }.squish
    end

    def flag_notice_wiki_page
      "help:flag_notice"
    end

    def appeal_notice_wiki_page
      "help:appeal_notice"
    end

    def replacement_notice_wiki_page
      "help:replacement_notice"
    end

    # The number of posts displayed per page.
    def posts_per_page
      75
    end

    def max_posts_per_page
      320
    end

    def minimum_general_tags
      10
    end

    def base_upload_approved
      5
    end

    def base_upload_deleted
      2
    end

    def is_post_restricted?(post)
      false
    end

    # TODO: Investigate what this does and where it is used.
    def is_user_restricted?(user)
      !user.is_privileged?
    end

    def can_user_see_post?(user, post)
      return false if post.is_deleted? && !user.is_moderator?
      if is_user_restricted?(user) && is_post_restricted?(post)
        false
      else
        true
      end
    end

    def user_needs_login_for_post?(post)
      false
    end

    def select_posts_visible_to_user(user, posts)
      posts.select {|x| can_user_see_post?(user, x)}
    end

    def max_appeals_per_day
      1
    end

    # Counting every post is typically expensive because it involves a sequential scan on
    # potentially millions of rows. If this method returns a value, then blank searches
    # will return that number for the fast_count call instead.
    def blank_tag_search_fast_count
      nil
    end

    def pixiv_login
      nil
    end

    def pixiv_password
      nil
    end

    def nico_seiga_login
      nil
    end

    def nico_seiga_password
      nil
    end

    def nijie_login
      nil
    end

    def nijie_password
      nil
    end

    # Register at https://www.deviantart.com/developers/.
    def deviantart_client_id
      nil
    end

    def deviantart_client_secret
      nil
    end

    # http://tinysubversions.com/notes/mastodon-bot/
    def pawoo_client_id
      nil
    end

    def pawoo_client_secret
      nil
    end

    # 1. Register app at https://www.tumblr.com/oauth/register.
    # 2. Copy "OAuth Consumer Key" from https://www.tumblr.com/oauth/apps.
    def tumblr_consumer_key
      nil
    end

    def enable_dimension_autotagging?
      true
    end

    # Should return true if the given tag should be suggested for removal in the post replacement dialog box.
    def remove_tag_after_replacement?(tag)
      tag =~ /\A(?:replaceme|.*_sample|resized|upscaled|downscaled|md5_mismatch|jpeg_artifacts|corrupted_image|source_request)\z/i
    end

    # Posts with these tags will be highlighted yellow in the modqueue.
    def modqueue_quality_warning_tags
      %w[hard_translated self_upload nude_filter third-party_edit screencap]
    end

    # Posts with these tags will be highlighted red in the modqueue.
    def modqueue_sample_warning_tags
      %w[duplicate image_sample md5_mismatch resized upscaled downscaled]
    end

    def twitter_api_key
    end

    def twitter_api_secret
    end

    # The default headers to be sent with outgoing http requests. Some external
    # services will fail if you don't set a valid User-Agent.
    def http_headers
      {
        "User-Agent" => "#{Danbooru.config.safe_app_name}/#{Danbooru.config.version}",
      }
    end

    def httparty_options
      # proxy example:
      # {http_proxyaddr: "", http_proxyport: "", http_proxyuser: nil, http_proxypass: nil}
      {
        timeout: 10,
        open_timout: 5,
        headers: Danbooru.config.http_headers,
      }
    end

    # you should override this
    def email_key
    end

    def mail_from_addr
      "api@yiff.rocks"
    end

    def smtp_address
      "smtp.gmail.com"
    end

    def smtp_port
      587
    end

    def smtp_domain
      "yiff.rocks"
    end

    def smtp_username
      mail_from_addr
    end

    def smtp_password
    end

    def smtp_authentication
      "plain"
    end

    def smtp_tls
      true
    end

    # For downloads, if the host matches any of these IPs, block it
    def banned_ip_for_download?(ip_addr)
      raise ArgumentError unless ip_addr.is_a?(IPAddr)
      ipv4s = %w(127.0.0.1/8 169.254.0.0/16 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16)
      ipv6s = %w(::1 fe80::/10 fd00::/8)


      if ip_addr.ipv4?
        ipv4s.any? {|range| IPAddr.new(range).include?(ip_addr)}
      elsif ip_addr.ipv6?
        ipv6s.any? {|range| IPAddr.new(range).include?(ip_addr)}
      else
        false
      end
    end

    def twitter_site
    end

    # disable this for tests
    def enable_sock_puppet_validation?
      true
    end

    def iqdbs_server
    end

    def elasticsearch_host
    end

    # Use a recaptcha on the signup page to protect against spambots creating new accounts.
    # https://developers.google.com/recaptcha/intro
    def enable_recaptcha?
      Rails.env.production? && Danbooru.config.recaptcha_site_key.present? && Danbooru.config.recaptcha_secret_key.present?
    end

    def recaptcha_site_key
    end

    def recaptcha_secret_key
    end

    def enable_image_cropping?
      true
    end

    # Akismet API key. Used for Dmail spam detection. http://akismet.com/signup/
    def rakismet_key
    end

    def rakismet_url
      "https://#{hostname}"
    end

    def redis_url
    end

    def bypass_upload_whitelist?(user)
      user.is_admin?
    end

    def ads_enabled?
      false
    end

    def ads_zone_desktop
      {zone: nil, revive_id: nil, checksum: nil}
    end

    def ads_zone_mobile
      {zone: nil, revive_id: nil, checksum: nil}
    end

    # if anyone wants to make up some better mascots, feel free - you don't need to supply the blurred version
    def mascots
      [
        # ["/images/mascots/strobes/1.png", "#222222", "<a href='https://twitter.com/SmellyStrobes'>@SmellyStrobes</a> on <a href='https://twitter.com/SmellyStrobes/status/880768939302715392'>Twitter</a>"],
        # ["/images/mascots/strobes/2.png", "#222222", "<a href='https://twitter.com/SmellyStrobes'>@SmellyStrobes</a> on <a href='https://twitter.com/SmellyStrobes/status/1017809075550277637'>Twitter</a>"],
          ["/images/mascots/strobes/3.png", "#222222", "<a href='https://twitter.com/SmellyStrobes'>@SmellyStrobes</a> on <a href='https://twitter.com/FursuitButtsRev/status/1199145749155479552'>Twitter</a>"]
      ]
    end

    def metrika_enabled?
      false
    end

    # Additional video samples will be generated in these dimensions if it makes sense to do so
    # They will be available as additional scale options on applicable posts in the order they appear here
    def video_rescales
      {'720p' => [1280, 720], '480p' => [640, 480]}
    end

    def image_rescales
      []
    end

    def readonly_mode?
      false
    end
  end

  class EnvironmentConfiguration
    def custom_configuration
      @custom_configuration ||= CustomConfiguration.new
    end

    def env_to_boolean(method, var)
      is_boolean = method.to_s.end_with? "?"
      return true if is_boolean && var.truthy?
      return false if is_boolean && var.falsy?
      var
    end

    def method_missing(method, *args)
      var = ENV["DANBOORU_#{method.to_s.upcase.chomp("?")}"]

      if var.present?
        env_to_boolean(method, var)
      else
        custom_configuration.send(method, *args)
      end
    end
  end

  def config
    @configuration ||= EnvironmentConfiguration.new
  end

  module_function :config
end
