# Kilometric

A fast **stats aggregation** service written in Crystal using **Redis streams** as a data store.

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

### GET /metric

Allows you to read aggregated data for a particular metric.

**Count all values** of a metric:

```
curl http://localhost:3000/metric?key=my-metric&type=counter

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
curl http://localhost:3000/metric?key=my-metric&type=counter&from=1603303544000&to=1603311712000

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
curl http://localhost:3000/metric?key=my-metric&type=points 

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
curl http://localhost:3000/metric?key=my-metric&type=points&period=3600

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
curl http://localhost:3000/metric?key=my-metric&type=points&from=1603303544000&to=1603311712000

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

If something went wrong (e.g. the background processing was halted):

```
curl http://localhost:3000/health

HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json

{"status":"error"}
```

## Installation

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

You can **configure** the app with the following environment variables:

- `KILOMETRIC_REDIS_URL`: Defaults to *redis://localhost:6379/0*.
- `KILOMETRIC_FLUSH_INTERVAL`: The rate in seconds at which buffered metrics will be flushed into Redis. Defaults to *60*.
- `KILOMETRIC_PORT`: The web port to use. Defaults to *3000*.

## Development

Build the `sentry` tool (refresh your server on code changes):

```sh
crystal build lib/sentry/src/sentry_cli.cr -o sentry
```

Run your app via `sentry` to watch for code changes:

```sh
./sentry
```
