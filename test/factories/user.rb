# frozen_string_literal: true

FactoryBot.define do
  factory(:user, aliases: %i[creator updater]) do
    sequence(:name) do |n|
      "user#{n}"
    end
    password { "password" }
    password_confirmation { "password" }
    sequence(:email) { |n| "user_email_#{n}@example.com" }
    default_image_size { "large" }
    base_upload_limit { 10 }
    level { User::Levels::MEMBER }
    created_at { Time.now }
    last_logged_in_at { Time.now }
    email_verified { true }
    upload_notifications { User.upload_notifications_options }

    factory(:anonymous_user) do
      level { User::Levels::ANONYMOUS }
    end

    factory(:banned_user) do
      transient { ban_duration { 3 } }
      level { User::Levels::BANNED }
    end

    factory(:restricted_user) do
      level { User::Levels::RESTRICTED }
    end

    factory(:rejected_user) do
      level { User::Levels::REJECTED }
    end

    factory(:member_user) do
      level { User::Levels::MEMBER }
    end

    factory(:trusted_user) do
      level { User::Levels::TRUSTED }
    end

    factory(:former_staff_user) do
      level { User::Levels::FORMER_STAFF }
    end

    factory(:janitor_user) do
      level { User::Levels::JANITOR }
      unrestricted_uploads { true }
      can_approve_posts { true }
    end

    factory(:moderator_user) do
      level { User::Levels::MODERATOR }
    end

    factory(:system_user) do
      level { User::Levels::SYSTEM }
    end

    factory(:admin_user) do
      level { User::Levels::ADMIN }
      can_approve_posts { true }
      can_manage_aibur { true }
    end

    factory(:owner_user) do
      level { User::Levels::OWNER }
      can_approve_posts { true }
      can_manage_aibur { true }
    end

    factory(:user_with_mfa) do
      mfa_secret { MFA.generate_secret }
      backup_codes { generate_backup_codes }
    end
  end
end
