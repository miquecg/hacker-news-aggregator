import Config

config :hacker_news, :api, host: "hacker-news.firebaseio.com"

config :logger,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ],
  handle_sasl_reports: true

import_config "#{config_env()}.exs"
