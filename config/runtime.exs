import Config

if System.get_env("RELEASE_MODE") do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      """

  port =
    System.get_env("PORT") ||
      raise """
      environment variable PORT is missing.
      """

  config :hacker_news, :web,
    port: String.to_integer(port),
    secret_key_base: secret_key_base
end
