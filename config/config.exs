import Config

alias HackerNewsApi.Client.FinchAdapter

config :hacker_news, :api,
  adapter: FinchAdapter,
  host: "hacker-news.firebaseio.com"

config :hacker_news, :web,
  secret_key_base: "k1W7Ot6HLAxKsbVOXCc/wnSsRv8Wz0JGRRpraFc058SP1GFs0n3SYdqGTWyyTSLx"

config :logger,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ],
  handle_sasl_reports: true

import_config "#{config_env()}.exs"
