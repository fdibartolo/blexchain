use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :blexchain, Blexchain.Endpoint,
  http: [port: 4001],
  server: false

# 'Inject' fake http client
config :blexchain, http_client: Blexchain.FakeClient

# Proof of Work quantity of zeroes (so tests run faster)
config :blexchain, pow_zeroes: "0"

# Print only warnings and errors during test
config :logger, level: :warn
