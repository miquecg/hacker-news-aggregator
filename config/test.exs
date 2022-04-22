import Config

config :hacker_news, :web, port: 4002

config :logger,
  handle_sasl_reports: false,
  level: :error
