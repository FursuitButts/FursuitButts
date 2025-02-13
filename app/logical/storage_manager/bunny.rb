# frozen_string_literal: true

require "net/ftp"

module StorageManager
  class Bunny < StorageManager::Ftp
    attr_reader :secret_token, :api_key

    def initialize(host:, port:, username:, password:, secret_token:, api_key:, **options)
      super(host: host, port: port, username: username, password: password, **options)
      @secret_token = secret_token
      @api_key = api_key
    end

    def protected_params(url, _post, _secret: nil)
      user_id = CurrentUser.id
      time = (Time.now + 15.minutes).to_i
      hash = Digest::SHA2.base64digest("#{secret_token}#{url}#{time}token_path=#{url}&user=#{user_id}")
                         .tr("+", "-").tr("/", "_").tr("=", "")
      "?token=#{hash}&token_path=#{URI.encode_uri_component(url)}&expires=#{time}&user=#{user_id}"
    end

    def purge_cache(url)
      conn = Faraday.new(FemboyFans.config.faraday_options) do |r|
        r.headers["AccessKey"] = api_key
      end
      conn.post("https://api.bunny.net/purge?async=false&url=#{CGI.escape(url)}").success?
    end

    def delete(path)
      super
      purge_cache("#{base_url}#{path}")
    end
  end
end
