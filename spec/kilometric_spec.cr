ENV["KEMAL_ENV"] = "test"

require "spec"
require "spec-kemal"
require "../src/kilometric"

private def redis
  @redis ||= MiniRedis.new(uri: URI.parse("redis://localhost:6379/0"))
end

describe Kilometric do
  it "GET /track" do
    get "/track?key=my-metric"

    response.status.should eq(HTTP::Status::NO_CONTENT)
    response.body.should be_empty
  end

  it "GET /track with a value" do
    get "/track?key=my-metric&value=5"

    response.status.should eq(HTTP::Status::NO_CONTENT)
    response.body.should be_empty
  end

  it "GET /health" do
    get "/health"

    response.status.should eq(HTTP::Status::OK)
    response.body.should eq({ "status" => "ok" }.to_json)
  end
end
