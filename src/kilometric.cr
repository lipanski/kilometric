require "kemal"
require "mini_redis"
require "json"

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

  def self.last_flushed_at : Time
    @@last_flushed_at || Time::UNIX_EPOCH
  end

  def self.update_last_flushed_at
    @@last_flushed_at = Time.utc
  end

  class Metric(T)
    include JSON::Serializable

    property name : String
    property values : Array(T)

    def initialize(@name, @values : Array(T)); end
  end

  class Counter
    include JSON::Serializable

    property from : UInt64
    property to : UInt64
    property value : UInt64

    def initialize(@from, @to, @value); end
  end

  class Point
    include JSON::Serializable

    property from : UInt64
    property value : UInt64

    def initialize(@from, @value); end
  end

  class RedisStore
    def initialize(redis_url : String)
      @redis = MiniRedis.new(uri: URI.parse(redis_url))
      @buffer = Hash(String, UInt32).new
      @namespace = "kilometric"
    end

    def write(key : String, value : UInt64)
      @buffer[key] ||= 0u64
      @buffer[key] += value
    end

    def counter(key : String, from : String, to : String) : Metric(Counter)
      points = read(key, from, to)
      return Metric.new(key, Array(Counter).new) if points.empty?

      actual_from = points.first[0]
      actual_to = points.last[0]
      value = points.sum { |point| point[1] }
      counter = Counter.new(actual_from, actual_to, value)

      Metric.new(key, [counter])
    end

    def points(key : String, from : String, to : String, period : Int32) : Metric(Point)
      points = Array(Point).new

      read(key, from, to).each do |point|
        bucket = point[0] - point[0] % period
        value = point[1]

        if points.last? && points.last.from == bucket
          points.last.value += value
        else
          points << Point.new(bucket, value)
        end
      end

      Metric.new(key, points)
    end

    def rate
      # TODO
    end

    def gauge
      # TODO
    end

    def flush!
      @buffer.each_key do |key|
        value = @buffer.delete(key)
        next if value.nil? || value.zero?

        @redis.send("XADD", namespaced(key), "*", "count", value)
      end
    end

    private def read(key : String, from : String, to : String) : Array({UInt64, UInt64})
      points = @redis.send("XRANGE", namespaced(key), from, to).raw.as(Array(MiniRedis::Value))
      points.map do |point|
        point = point.raw.as(Array(MiniRedis::Value))

        time = String.new(point[0].raw.as(Bytes)).split("-").first.to_u64
        key, value = point[1].raw.as(Array(MiniRedis::Value))
        value = String.new(value.raw.as(Bytes)).to_u64

        { time, value }
      end
    end

    private def namespaced(key : String) : String
      @namespace + "." + key
    end
  end
end

get "/read" do |env|
  key = env.params.query["key"]
  type = env.params.query["type"]
  from = env.params.query["from"]? || "-"
  to = env.params.query["to"]? || "+"
  period = env.params.query.has_key?("period") ? env.params.query["period"].to_i : 60

  env.response.content_type = "application/json"

  case type
  when "counter"
    Kilometric.store.counter(key, from, to).to_json
  when "points"
    Kilometric.store.points(key, from, to, period).to_json
  else
    "{}"
  end
end

get "/track" do |env|
  key = env.params.query["key"]
  value = env.params.query.has_key?("value") ? env.params.query["value"].to_u64 : 1u64

  Kilometric.store.write(key, value)

  env.response.status = HTTP::Status::NO_CONTENT
end

get "/health" do |env|
  env.response.content_type = "application/json"

  if Time.utc - Kilometric.last_flushed_at > Time::Span.new(seconds: Kilometric.flush_interval * 10)
    halt(env, status_code: 422, response: ({"status" => "error"}.to_json))
  end

  {"status" => "ok"}.to_json
end

spawn do
  loop do
    Kilometric.store.flush!
    Kilometric.update_last_flushed_at
    sleep(Kilometric.flush_interval)
  end
end

Kemal.run(Kilometric.port)

