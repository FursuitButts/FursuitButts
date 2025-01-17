FactoryBot.define do
  factory(:user, aliases: [:creator, :updater]) do
    sequence :name do |n|
      "user#{n}"
    end
    password { "password" }
    password_confirmation { "password" }
    password_hash {"password"}
    email {FFaker::Internet.email}
    default_image_size { "large" }
    base_upload_limit { 10 }
    level { 20 }
    created_at {Time.now}
    last_logged_in_at {Time.now}
    bit_prefs { 0 }

    factory(:banned_user) do
      transient { ban_duration { 3 } }
      is_banned { true }
    end

    factory(:member_user) do
      level { 20 }
    end

    factory(:privileged_user) do
      level { 30 }
    end

    factory(:janitor_user) do
      level { 33 }
      bit_prefs { User.flag_value_for("can_upload_free") }
      can_approve_posts { true }
    end

    factory(:curator_user) do
      level { 31 }
      bit_prefs { User.flag_value_for("can_upload_free") }
    end

    factory(:curator_user) do
      level { 31 }
      bit_prefs { User.flag_value_for("can_upload_free") }
    end

    factory(:moderator_user) do
      level { 40 }
      can_approve_posts { true }
    end

    factory(:mod_user) do
      level { 40 }
      can_approve_posts { true }
    end

    factory(:admin_user) do
      level { 50 }
      can_approve_posts { true }
    end
  end
end
