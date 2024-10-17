# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
ENV["MT_NO_EXPECTATIONS"] = "true"
require_relative "../config/environment"
require "rails/test_help"

require "factory_bot_rails"
require "mocha/minitest"
require "shoulda-context"
require "shoulda-matchers"
require "webmock/minitest"
require "simplecov"
SimpleCov.start

require "simplecov-cobertura"
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

require "sidekiq/testing"
Sidekiq::Testing.fake!
# https://github.com/sidekiq/sidekiq/issues/5907#issuecomment-1536457365
Sidekiq.configure_client do |cfg|
  cfg.logger.level = Logger::WARN
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework(:minitest)
    with.library(:rails)
  end
end

WebMock.disable_net_connect!(allow: [
  FemboyFans.config.opensearch_host,
])

FactoryBot::SyntaxRunner.class_eval do
  include ActiveSupport::Testing::FileFixtures
  include ActionDispatch::TestProcess::FixtureFile
  self.file_fixture_path = ActiveSupport::TestCase.file_fixture_path
end

# Make tests not take ages. Remove the const first to avoid a const redefinition warning.
BCrypt::Engine.send(:remove_const, :DEFAULT_COST)
BCrypt::Engine::DEFAULT_COST = BCrypt::Engine::MIN_COST

# Clear the opensearch indicies completly
Post.document_store.create_index!(delete_existing: true)
PostVersion.document_store.create_index!(delete_existing: true)

class ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  include ActionDispatch::TestProcess::FixtureFile
  include FactoryBot::Syntax::Methods

  setup do
    Socket.stubs(:gethostname).returns("www.example.com")
    FemboyFans.config.stubs(:enable_sock_puppet_validation?).returns(false)
    FemboyFans.config.stubs(:disable_throttles?).returns(true)
    FemboyFans.config.stubs(:reports_enabled?).returns(false)

    FileUtils.mkdir_p(Rails.root.join("tmp/test-storage2").to_s)
    storage_manager = StorageManager::Local.new(base_dir: Rails.root.join("tmp/test-storage2").to_s)
    FemboyFans.config.stubs(:storage_manager).returns(storage_manager)
    FemboyFans.config.stubs(:backup_storage_manager).returns(StorageManager::Null.new)
    FemboyFans.config.stubs(:enable_email_verification?).returns(false)
    CurrentUser.ip_addr = "127.0.0.1"
  end

  teardown do
    # The below line is only mildly insane and may have resulted in the destruction of my data several times.
    FileUtils.rm_rf(Rails.root.join("tmp/test-storage2").to_s)
    Cache.clear
    RequestStore.clear!
  end

  def as(user, ip_addr = "127.0.0.1", &)
    CurrentUser.scoped(user, ip_addr, &)
  end

  def with_inline_jobs(&)
    Sidekiq::Testing.inline!(&)
  end

  def reset_post_index
    # This seems slightly faster than deleting and recreating the index
    Post.document_store.delete_by_query(query: "*", body: {})
    Post.document_store.refresh_index!
  end

  def mock_request(remote_ip: "127.0.0.1", user_agent: "Firefox", session_id: "1234")
    request = mock
    request.stubs(:remote_ip).returns(remote_ip)
    request.stubs(:user_agent).returns(user_agent)
    request.stubs(:session).returns(session_id: session_id)
    request.stubs(:parameters).returns({})
    request.stubs(:delete).with(:user_id).returns(nil)
    request.stubs(:delete).with(:last_authenticated_at).returns(nil)
    request
  end
end

class ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  def login_as(user)
    post(session_path, params: { session: { name: user.name, password: user.password } })

    if user.mfa.present?
      post(verify_mfa_session_path, params: { mfa: { user_id: user.signed_id(purpose: :verify_mfa), code: user.mfa.code } })
    end
  end

  def method_authenticated(method_name, url, user, options)
    login_as(user)
    send(method_name, url, **options)
  end

  def get_auth(url, user, options = {})
    method_authenticated(:get, url, user, options)
  end

  def post_auth(url, user, options = {})
    method_authenticated(:post, url, user, options)
  end

  def put_auth(url, user, options = {})
    method_authenticated(:put, url, user, options)
  end

  def delete_auth(url, user, options = {})
    method_authenticated(:delete, url, user, options)
  end

  def assert_error_response(key, *messages)
    assert_not_nil(@response.parsed_body.dig("errors", key))
    assert_same_elements(messages, @response.parsed_body.dig("errors", key))
  end

  def assert_access(minlevel, success_response: :success, fail_response: :forbidden, anonymous_response: nil, &)
    all = User::Levels.constants.map { |c| User::Levels.const_get(c) }.select { |l| l > User::Levels::BANNED && l < User::Levels::LOCKED }.sort
    if minlevel.is_a?(Integer)
      success = all.select { |l| l >= minlevel }
      fail = all.select { |l| l < minlevel }
    else
      success = minlevel
      fail = all.reject { |l| minlevel.include?(l) }
    end
    createuser = ->(level) { create(:"#{User::Levels.id_to_name(level).downcase.gsub(' ', '_')}_user") }

    success.each do |level|
      user = createuser.call(level)
      as(user) { yield(user) }
      assert_response(success_response, "Success: #{User::Levels.id_to_name(level)} (expected: #{success_response}, actual: #{@response.status})")
    end

    fail.each do |level|
      user = createuser.call(level)
      as(user) { yield(user) }
      assert_response(fail_response, "Fail: #{User::Levels.id_to_name(level)} (expected: #{fail_response}, actual: #{@response.status})")
    end

    User::Levels::ANONYMOUS.tap do |level|
      user = createuser.call(level)
      as(user) { yield(user) }
      anon = anonymous_response || (fail_response == :forbidden ? :redirect : fail_response)
      anonmin = minlevel.is_a?(Integer) ? minlevel > User::Levels::ANONYMOUS : minlevel.exclude?(User::Levels::ANONYMOUS)
      if anonmin || anonymous_response.present?
        assert_response(anon, "Fail: #{User::Levels.id_to_name(level)} (expected: #{anon}, actual: #{@response.status})")
      else
        assert_response(:success, "Fail: #{User::Levels.id_to_name(level)} (expected: success, actual: #{@response.status})")
      end
    end

    User::Levels::BANNED.tap do |level|
      user = createuser.call(level)
      admin = create(:admin_user)
      as(admin) { create(:ban, user: user, reason: "test") }
      as(user) { yield(user) }
      assert_response(:forbidden, "Fail: #{User::Levels.id_to_name(level)} (expected: forbidden, actual: #{@response.status})")
    end
  end
end

module ActionView
  class TestCase
    # Stub webpacker method so these tests don't compile assets
    def asset_pack_path(name, **_options)
      name
    end
  end
end

Rails.application.load_seed
