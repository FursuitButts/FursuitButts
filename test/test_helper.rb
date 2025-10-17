# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
ENV["MT_NO_EXPECTATIONS"] = "true"
require_relative("../config/environment")
require("rails/test_help")

require("factory_bot_rails")

require("mocha/minitest")
require("shoulda-context")
require("shoulda-matchers")
require("webmock/minitest")
require("simplecov")
SimpleCov.start

require("simplecov-cobertura")
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

require("sidekiq/testing")

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
  FemboyFans.config.elasticsearch_host,
])

FactoryBot::SyntaxRunner.class_eval do
  include(ActiveSupport::Testing::FileFixtures)
  include(ActionDispatch::TestProcess::FixtureFile)
  self.file_fixture_path = ActiveSupport::TestCase.file_fixture_path
end

# Make tests not take ages. Remove the const first to avoid a const redefinition warning.
BCrypt::Engine.send(:remove_const, :DEFAULT_COST)
BCrypt::Engine::DEFAULT_COST = BCrypt::Engine::MIN_COST

# Clear the elasticsearch indicies completly
Post.document_store.create_index!(delete_existing: true)
PostVersion.document_store.create_index!(delete_existing: true)

class ActiveSupport::TestCase # rubocop:disable Style/ClassAndModuleChildren
  include(ActionDispatch::TestProcess::FixtureFile)
  include(FactoryBot::Syntax::Methods)

  storage_root = Rails.root.join("tmp/test-storage2").to_s
  setup do
    Socket.stubs(:gethostname).returns("www.example.com")
    Config.any_instance.stubs(:enable_sock_puppet_validation).returns(false)
    FemboyFans.config.stubs(:disable_throttles?).returns(true)
    FemboyFans.config.stubs(:reports_enabled?).returns(false)

    FileUtils.mkdir_p(storage_root)
    %w[posts replacements mascots].each do |dir|
      FileUtils.mkdir_p(File.join(storage_root, dir))
    end
    storage_manager = StorageManager::Local.new(base_dir: storage_root)
    FemboyFans.config.stubs(:storage_manager).returns(storage_manager)
    FemboyFans.config.stubs(:backup_storage_manager).returns(StorageManager::Null.new)
    Config.any_instance.stubs(:flag_ai_posts).returns(false)
    Config.any_instance.stubs(:tag_ai_posts).returns(false)
    Config.any_instance.stubs(:enable_email_verification).returns(false)
  end

  teardown do
    # The below line is only mildly insane and may have resulted in the destruction of my data several times.
    FileUtils.rm_rf(storage_root)
    Cache.clear
    RequestStore.clear!
  end

  def with_inline_jobs(&)
    Sidekiq::Testing.inline!(&)
  end

  def reset_post_index
    # This seems slightly faster than deleting and recreating the index
    Post.document_store.delete_by_query(query: "*", body: {})
    Post.document_store.refresh_index!
  end

  def mock_request(remote_ip: "127.0.0.1", host: "localhost", user_agent: "Firefox", session_id: "1234", parameters: {})
    cookie_jar = mock
    cookie_jar.stubs(:encrypted).returns({})
    request = mock
    request.stubs(:host).returns(host)
    request.stubs(:remote_ip).returns(remote_ip)
    request.stubs(:user_agent).returns(user_agent)
    request.stubs(:authorization).returns(nil)
    request.stubs(:session).returns(session_id: session_id)
    request.stubs(:parameters).returns(parameters)
    request.stubs(:delete).with(:user_id).returns(nil)
    request.stubs(:delete).with(:last_authenticated_at).returns(nil)
    request.stubs(:cookie_jar).returns(cookie_jar)
    request
  end

  def random
    SecureRandom.hex(6)
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
      ApplicationRecord.transaction do
        yield(user)
        assert_response(success_response, "Success: #{User::Levels.id_to_name(level)} (expected: #{success_response}, actual: #{@response.status})")
        raise(ActiveRecord::Rollback)
      end
    end

    fail.each do |level|
      user = createuser.call(level)
      ApplicationRecord.transaction do
        yield(user)
        assert_response(fail_response, "Fail: #{User::Levels.id_to_name(level)} (expected: #{fail_response}, actual: #{@response.status})")
        raise(ActiveRecord::Rollback)
      end
    end

    User::Levels::ANONYMOUS.tap do |level|
      user = createuser.call(level)
      ApplicationRecord.transaction do
        yield(user)
        anon = anonymous_response || (fail_response == :forbidden ? :redirect : fail_response)
        anonmin = minlevel.is_a?(Integer) ? minlevel > User::Levels::ANONYMOUS : minlevel.exclude?(User::Levels::ANONYMOUS)
        if anonmin || anonymous_response.present?
          assert_response(anon, "Fail: #{User::Levels.id_to_name(level)} (expected: #{anon}, actual: #{@response.status})")
        else
          assert_response(:success, "Fail: #{User::Levels.id_to_name(level)} (expected: success, actual: #{@response.status})")
        end
        raise(ActiveRecord::Rollback)
      end
    end

    User::Levels::BANNED.tap do |level|
      user = createuser.call(level)
      ApplicationRecord.transaction do
        admin = create(:admin_user)
        create(:ban, user: user, reason: "test", creator: admin)
        yield(user)
        assert_response(:forbidden, "Fail: #{User::Levels.id_to_name(level)} (expected: forbidden, actual: #{@response.status})")
        raise(ActiveRecord::Rollback)
      end
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

# XXX Testing modules should not have a say in if we can or cannot use assert_equal with nil
# https://github.com/minitest/minitest/issues/666
# TODO: look into refactoring out minitest?
module Minitest
  module Assertions
    def assert_equal(exp, act, msg = nil)
      assert(exp == act, message(msg, E) { diff(exp, act) })
    end
  end
end

Rails.application.load_seed
