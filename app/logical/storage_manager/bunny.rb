# frozen_string_literal: true

require "net/ftp"

module StorageManager
  class Bunny < StorageManager::Ftp
    TEMP_DIR = "/tmp"
    attr_reader :secret_token

    def initialize(host, port, user, password, secret_token, **options)
      @host = host
      @port = port
      @user = user
      @password = password
      @secret_token = secret_token
      super(host, port, user, password, **options)
    end

    def protected_params(url, _post, _secret: nil)
      user_id = CurrentUser.id
      time = (Time.now + 15.minutes).to_i
      hash = Digest::SHA2.base64digest("#{secret_token}#{url}#{time}token_path=#{url}&user=#{user_id}")
                         .tr("+", "-").tr("/", "_").tr("=", "")
      "?token=#{hash}&token_path=#{URI.encode_uri_component(url)}&expires=#{time}&user=#{user_id}"
    end
  end
end
