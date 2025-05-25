import Config

config :finitomata, :telemetria, true

config :telemetria,
  backend: Telemetria.Backend.Persistomata,
  purge_level: :debug,
  level: :info,
  events: []

config :rambla,
  stub: [
    connections: [stubbed: :conn],
    channels: [logger: [connection: :stubbed]]
  ]
