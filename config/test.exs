import Config

# DETS storage configuration for test environment
config :mark_point, :dets,
  file_path: "priv/test_notes"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mark_point, MarkPointWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "NqLT/P76+KXPZkJ8tGJMmVLBzjT0hBtHQpEwCeaXzBQLmHQKo9LUiPaGE1RsM5Jq",
  server: false

# In test we don't send emails
config :mark_point, MarkPoint.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
