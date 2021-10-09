class YiffyApiController < ApplicationController
  def index
      render json: {
        type: params[:category],
	     test: "e"
      }.to_json
    end
  end
end
