require "kemal"
require "mini_redis"

module Kilometric
  def self.store : RedisStore
    @@store ||= RedisStore.new(ENV.fetch("KILOMETRIC_REDIS_URL", "redis://localhost:6379/0"))
  end

  def self.flush_interval
    @@flush_interval ||= Int32.new(ENV.fetch("KILOMETRIC_FLUSH_INTERVAL", "60"))
  end

  def self.port
    @@port ||= Int32.new(ENV.fetch("KILOMETRIC_PORT", "3000"))
  end

  class RedisStore
    def initialize(redis_url : String)
      @redis = MiniRedis.new(uri: URI.parse(redis_url))
      @buffer = Hash(String, UInt32).new
      @namespace = "kilometric"
    end

    def write(metric : String, value : UInt64)
      @buffer[metric] ||= 0u64
      @buffer[metric] += value
    end

    def read(metric : String, from : String = "-", to : String = "+") : UInt64
      points = @redis.send("XRANGE", namespaced(metric), from, to).raw.as(Array(MiniRedis::Value))
      points.reduce(0u64) do |counter, point|
        point = point.raw.as(Array(MiniRedis::Value))

        time = String.new(point[0].raw.as(Bytes)).split("-").first.to_u64
        key, value = point[1].raw.as(Array(MiniRedis::Value))

        value = String.new(value.raw.as(Bytes)).to_u64
        counter += value
      end
    end

    def flush!
      @buffer.each_key do |key|
        value = @buffer.delete(key)
        next if value.nil? || value.zero?

        @redis.send("XADD", namespaced(key), "*", "count", value)
      end
    end

    private def namespaced(key : String) : String
      @namespace + "." + key
    end
  end
end

get "/v1/counter/:metric" do |env|
  metric = env.params.url["metric"]
  from = env.params.query["from"]? || "-"
  to = env.params.query["to"]? || "+"

  Kilometric.store.read(metric, from, to).to_s
end

post "/v1/counter/:metric" do |env|
  metric = env.params.url["metric"]
  value = env.params.query.has_key?("value") ? env.params.query["value"].to_u64 : 1u64

  Kilometric.store.write(metric, value)

  env.response.status = HTTP::Status::NO_CONTENT
end

spawn do
  loop do
    sleep(Kilometric.flush_interval)
    Kilometric.store.flush!
  end
end

Kemal.run(Kilometric.port)

