require "swagger_helper"

RSpec.describe "Health API", type: :request do
  path "/api/v1/health" do
    get "Health check" do
      tags "System"
      produces "application/json"

      response "200", "service is healthy" do
        run_test!
      end
    end
  end
end
