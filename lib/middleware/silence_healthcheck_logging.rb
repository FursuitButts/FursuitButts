class SilenceHealthcheckLogging
  def initialize(app)
    @app = app
  end

  def call(env)
    if env["PATH_INFO"] == "/up"
      Rails.logger.silence do
        @app.call(env)
      end
    else
      @app.call(env)
    end
  end
end