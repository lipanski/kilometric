# Kilometric

A fast **stats aggregation** service written in Crystal using Redis streams as a data store.

Kilometric can process **1.6 million writes per minute**: 

```
wrk -t 100 -c 100 -d 10m http://localhost:3000/track?key=my-metric 
Running 10m test @ http://localhost:3000/track?key=my-metric
  100 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     4.01ms    4.61ms 191.65ms   97.57%
    Req/Sec   277.74    109.17    16.65k    94.74%
  16591245 requests in 10.00m, 1.79GB read
Requests/sec:  27647.49
Transfer/sec:  3.06MB
```

...with a very small dent to your Redis memory:

```
used_memory:876352 # Before (Bytes)
used_memory:877392 # After
```

## How does it work?

Kilometric tracks events by incrementing internal counters inside a buffer and flushing them periodically (every 10 seconds) to a Redis stream.

Redis streams are great for storing time series because:

- They assign a Unix timestamp to every piece of data.
- They are sorted chronologically.
- They are fast to slice and read.
- They are storage-efficient.
- You can contain their size easily either with your `maxmemory_policy` or with `XTRIM`.

## API

### GET /track

Allows you to track events, which usually means incrementing a counter.

**Track** an event:

```
curl http://localhost:3000/track?key=my-metric

HTTP/1.1 204 No Content
```

**Track** an event **multiple times**:

```
curl http://localhost:3000/track?key=my-metric&value=10

HTTP/1.1 204 No Content
```

### GET /read

Allows you to read aggregated data for a particular metric.

**Count all values** of a metric:

```
curl http://localhost:3000/read?key=my-metric&type=counter

HTTP/1.1 200 OK
Content-Type: application/json

{
  "name": "my-metric",
  "values": [
    {
      "from": 1603303544893,
      "to": 1603311711070,
      "value": 78
    }
  ]
}
```

**Count all values** of a metric for a **particular period of time**:

```
curl http://localhost:3000/read?key=my-metric&type=counter&from=1603303544000&to=1603311712000

HTTP/1.1 200 OK
Content-Type: application/json

{
  "name": "my-metric",
  "values": [
    {
      "from": 1603303544893,
      "to": 1603311711070,
      "value": 78
    }
  ]
}
```

**List all data points** of a metric in **sets of 60 seconds**:

```
curl http://localhost:3000/read?key=my-metric&type=points

HTTP/1.1 200 OK
Content-Type: application/json

{
  "name": "my-metric",
  "values": [
    {
      "from": 1603304960760,
      "value": 2
    },
    {
      "from": 1603305134340,
      "value": 4
    },
    {
      "from": 1603305139380,
      "value": 4
    },
    {
      "from": 1603305167700,
      "value": 6
    },
    {
      "from": 1603305172680,
      "value": 4
    },
    ...
  ]
}
```

**List all data points** of a metric in **sets of a particular amount of seconds**:

```
curl http://localhost:3000/read?key=my-metric&type=points&period=3600

HTTP/1.1 200 OK
Content-Type: application/json

{
  "name": "my-metric",
  "values": [
    {
      "from": 1603303542000,
      "value": 4
    },
    {
      "from": 1603303959600,
      "value": 1
    },
    {
      "from": 1603303963200,
      "value": 3
    },
    {
      "from": 1603304830800,
      "value": 5
    },
    {
      "from": 1603304838000,
      "value": 1
    },
    ...
  ]
}
```

**List all data points** of a metric for a **particular period of time**::

```
curl http://localhost:3000/read?key=my-metric&type=points&from=1603303544000&to=1603311712000

HTTP/1.1 200 OK
Content-Type: application/json

{
  "name": "my-metric",
  "values": [
    {
      "from": 1603304960760,
      "value": 2
    },
    {
      "from": 1603305134340,
      "value": 4
    },
    {
      "from": 1603305139380,
      "value": 4
    },
    {
      "from": 1603305167700,
      "value": 6
    },
    {
      "from": 1603305172680,
      "value": 4
    },
    ...
  ]
}
```

### GET /health

Provides a health check.

If everything goes **fine**:

```
curl http://localhost:3000/health

HTTP/1.1 200 OK
Content-Type: application/json

{"status":"ok"}
```

If something went **wrong** (e.g. the background processing was halted):

```
curl http://localhost:3000/health

HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json

{"status":"error"}
```

## Requirements

- Redis 5+

## Installation

Compiled binaries are available for Linux. Check the [releases](https://github.com/lipanski/kilometric/releases).

## Build from source

You'll need Crystal 0.35+ before getting started.

**Install** dependencies:

```sh
shards install
```

**Build** the binary for release:

```sh
crystal build --release src/kilometric.cr
```

**Run** the server on port 3000:

```sh
./kilometric
```

## Configuration

You can **configure** the app with the following **environment variables**:

- `KILOMETRIC_REDIS_URL`: Defaults to *redis://localhost:6379/0*.
- `KILOMETRIC_FLUSH_INTERVAL`: The rate in seconds at which buffered metrics will be flushed into Redis. Defaults to *10*.
- `KILOMETRIC_PORT`: The web port to use. Defaults to *3000*.

## Development

Build the `sentry` tool (refreshes your server on code changes):

```sh
crystal build lib/sentry/src/sentry_cli.cr -o sentry
```

Run the app with `sentry`:

```sh
./sentry
```
