# Hacker News Aggregator

The aggregator fetches top stories from Hacker News public API and stores them in memory. It's configured to check for new items every five minutes and attempts to keep them in similar order as they are presented on HN, meaning the front page (50 stories) is always sorted and older stories are gradually far back.

### HTTP API
It offers an HTTP API to query fetched stories serialized as `application/json`.

`GET /stories`
- Collection
- Pagination

`GET /stories/:id`
- Story

### WebSocket API
Upon connection to `/ws` endpoint current 50 top stories are sent. From that moment new stories are pushed whenever they are available. Each client receives what is new to them.

### Build
```
$ mix deps.get
$ MIX_ENV=prod mix release
```

### Run
```
$ SECRET_KEY_BASE=long-random-string PORT=4000 _build/prod/rel/app/bin/app start
```

### Hacker News API
- There's little to no validation of upstream data
- Client tries to avoid being blocked (exponential backoff)
- Stories are not updated once fetched

### Goals
- Leverage OTP and standard libraries
- Design an application resilient to failures
- Support many concurent clients
- Clear boundaries between components
- As much vanilla Elixir as possible

### Improvements
- Set a hard limit for the number of concurrent WebSocket connections
- Force clients to send a heartbeat message and close those inactive
- HTTP API rate limiting
- Compression and caching
- More testing

### References
- [Hacker News API](https://github.com/HackerNews/API)
- [Throttling and Blocking Bad Requests in Phoenix Web Applications with PlugAttack](https://www.paraxial.io/blog/throttle-requests)
