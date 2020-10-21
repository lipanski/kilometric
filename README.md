# Kilometric

Store and consume metrics as Redis streams.

## API

**Increment a counter** by 1:

```sh
curl -XPOST http://localhost:3000/api/counter/my-metric-name
```

**Increment a counter** by a particular value:

```sh
curl -XPOST http://localhost:3000/api/counter/my-metric-name?value=5
```

**Read** the value of a **counter**:

```sh
curl http://localhost:3000/api/counter/my-metric-name
```

**Read** the value of a **counter** for a particular period of time:

```sh
curl http://localhost:3000/api/counter/my-metric-name?from=1603267106&to=1603268201
```

## Installation

Install dependencies:

```sh
shards install
```

Build the binary:

```sh
crystal build src/kilometric.cr
```

Run the server:

```sh
./kilometric
```

You can **configure** the app with the following environment variables:

- `KILOMETRIC_REDIS_URL`: Defaults to *redis://localhost:6379/0*.
- `KILOMETRIC_REFRESH_RATE`: The rate at which buffered metrics should be pushed into Redis. Defaults to *60*.

## Development

Install shards:

```sh
shards install
```

Build `sentry` to refresh your server on code changes:

```sh
crystal build lib/sentry/src/sentry_cli.cr -o sentry
```

Run your app via `sentry` to watch for code changes:

```sh
sentry
```
