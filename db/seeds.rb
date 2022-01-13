# frozen_string_literal: true

require "digest/md5"
require "net/http"
require "tempfile"
require "securerandom"

unless Rails.env.test?
  puts "== Creating elasticsearch indices ==\n"

  Post.__elasticsearch__.create_index!
end

puts "== Seeding database with sample content ==\n"

# Uncomment to see detailed logs
#ActiveRecord::Base.logger = ActiveSupport::Logger.new($stdout)

admin_file = Rails.root.join("db", "admin.pwd")
system_file = Rails.root.join("db", "system.pwd")

if File.file?(admin_file)
  puts "Admin password file already exists, reusing.."
  admin_password = File.read(admin_file)
else
  puts "Admin password file does not exist, generating new password.."
  admin_password = SecureRandom.hex(20)
  File.write(admin_file, admin_password)
end

if File.file?(system_file)
  puts "System password file already exists, reusing.."
  system_password = File.read(system_file)
else
  puts "System password file does not exist, generating new password.."
  system_password = SecureRandom.hex(20)
  File.write(system_file, system_password)
end

admin = User.find_or_create_by!(name: "admin") do |user|
  puts "Setting admin password to: %s" % [ admin_password ]
  user.created_at = 2.weeks.ago
  user.password = admin_password
  user.password_confirmation = admin_password
  user.password_hash = ""
  user.email = "hewwo@yiff.rocks"
  user.can_upload_free = true
  user.can_approve_posts = true
  user.level = User::Levels::ADMIN
end

User.find_or_create_by!(name: Danbooru.config.system_user) do |user|
  puts "Setting system password to: %s" % [ system_password ]
  user.password = system_password
  user.password_confirmation = system_password
  user.password_hash = ""
  user.email = "api@yiff.rocks"
  user.can_upload_free = true
  user.can_approve_posts = true
  user.level = User::Levels::JANITOR
end

ForumCategory.find_or_create_by!(id: Danbooru.config.alias_implication_forum_category) do |category|
  category.name = "Tag Alias and Implication Suggestions"
  category.can_view = 0
end

unless Rails.env.production?
  CurrentUser.user = admin
    CurrentUser.ip_addr = "127.0.0.1"

  resources = YAML.load_file Rails.root.join("db", "seeds.yml")
  url = "https://e621.net/posts.json?limit=100&tags=id:" + resources["post_ids"].join(",")
  response = HTTParty.get(url, {
    headers: {"User-Agent" => "e621ng/seeding"}
  })
  json = JSON.parse(response.body)

  json["posts"].each do |post|
    puts post["file"]["url"]

    data = Net::HTTP.get(URI(post["file"]["url"]))
    file = Tempfile.new.binmode
    file.write data

    post["tags"].each do |category, tags|
      Tag.find_or_create_by_name_list(tags.map {|tag| category + ":" + tag})
    end

    md5 = Digest::MD5.hexdigest(data)
    service = UploadService.new({
      uploader_id: CurrentUser.id,
      uploader_ip_addr: CurrentUser.ip_addr,
      file: file,
      tag_string: post["tags"].values.flatten.join(" "),
      source: "https://e621.net/posts/#{post["id"]}\n" + post["sources"].join("\n"),
      description: post["description"],
      rating: post["rating"],
      md5: md5,
      md5_confirmation: md5
    })

    service.start!
  end
end
