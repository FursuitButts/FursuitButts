# frozen_string_literal: true

# https://github.com/plataformatec/responders
# https://github.com/plataformatec/responders/blob/master/lib/action_controller/responder.rb
class ApplicationResponder < ActionController::Responder
  # this is called by respond_with for non-html, non-js responses.
  def to_format
    params = request.params
    if get? && params["expires_in"]
      controller.expires_in(DurationParser.parse(params["expires_in"]))
    end

    options[:only] ||= params["only"] if params["only"]

    super
  end
end
