require File.expand_path('../../state_checker', __FILE__)

StateChecker.instance.check!

Rails.application.config.action_dispatch.session = {
  :key    => 'yiff',
  :secret => StateChecker.instance.session_secret_key
}
Rails.application.config.secret_key_base = StateChecker.instance.secret_token
