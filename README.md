# Kilometric

Store and consume metrics as Redis streams.

## API

**Increment a counter** by 1:

```sh
curl -XPOST http://localhost:3000/v1/counter/my-metric-name
```

**Increment a counter** by a particular value:

```sh
curl -XPOST http://localhost:3000/v1/counter/my-metric-name\?value=5
```

**Read** the value of a **counter**:

```sh
curl http://localhost:3000/v1/counter/my-metric-name
```

**Read** the value of a **counter** for a particular period of time, using Unix timestamps:

```sh
curl http://localhost:3000/v1/counter/my-metric-name\?from=1603267106\&to=1603268201
```

## Installation

**Install** dependencies:

```sh
shards install
```

**Build** the binary:

```sh
crystal build src/kilometric.cr
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
