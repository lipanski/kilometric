require "kemal"
require "mini_redis"

module Kilometric
  def self.store : RedisStore
    @@store ||= RedisStore.new(ENV.fetch("KILOMETRIC_REDIS_URL", "redis://localhost:6379/0"))
  end

  def self.refresh_rate
    @@refresh_rate ||= Int32.new(ENV.fetch("KILOMETRIC_REFRESH_RATE", "60"))
  end

  class RedisStore
    def initialize(redis_url : String)
      @redis = MiniRedis.new(uri: URI.parse(redis_url))
      @buffer = Hash(String, Int32).new
      @namespace = "kilometric"
    end

    def increment(metric : String, value : Nil)
      increment(metric)
    end

    def increment(metric : String, value : String)
      increment(metric, value.to_i)
    end

    def increment(metric : String, value : Int32 = 1)
      @buffer[metric] ||= 0
      @buffer[metric] += value
    end

    def counter(metric : String, from : String = "-", to : String = "+") : Int32
      values = @redis.send("XRANGE", namespaced(metric), from, to).raw.as(Array(MiniRedis::Value))
      values.reduce(0) do |counter, data|
        _, value = data.raw.as(Array(MiniRedis::Value))[1].raw.as(Array(MiniRedis::Value))
        count = Int32.new(String.new(value.raw.as(Bytes)))
        counter += count
      end
    end

    def flush!
      @buffer.each_key do |key|
        @redis.send("XADD", namespaced(key), "*", "count", @buffer.delete(key).to_s)
      end
    end

    private def namespaced(key : String) : String
      @namespace + "/" + key
    end
  end
end

get "/api/counter/:metric" do |env|
  metric = env.params.url["metric"]
  from = env.params.query["from"]? || "-"
  to = env.params.query["to"]? || "+"

  Kilometric.store.counter(metric, from, to).to_s
end

post "/api/counter/:metric" do |env|
  metric = env.params.url["metric"]
  value = env.params.query["value"]?

  Kilometric.store.increment(metric, value)
end

spawn do
  loop do
    sleep(Kilometric.refresh_rate)
    Kilometric.store.flush!
  end
end

Kemal.run

