class YiffyApiController < ApplicationController
  def index
    respond_to do |format|
      format.json do
        render json: {
          type: params[:category],
	      test: "e"
        }.to_json
      end
    end
  end
end
