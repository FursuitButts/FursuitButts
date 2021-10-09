class YiffyApiController < ApplicationController
  class APIErrors
    NOT_FOUND = {
      code: 0,
      message: "Not Found."
    }
  end

  def index
    render json: {
      type: params[:category],
	    test: "e"
    }.to_json
  end

  def not_found
    render json: {
      success: false,
      error: APIErrors::NOT_FOUND
    }.to_json
  end
end
