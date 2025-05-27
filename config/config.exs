import Config

config :finitomata, :telemetria, true

config :telemetria,
  backend: Telemetria.Backend.Persistomata,
  purge_level: :debug,
  level: :info,
  events: []

config :rambla,
  clickhouse: [
    # connections: [conn: "https://user:password@localhost:8123/some_database"],
    connections: [conn: "http://default:password@localhost:8123/default"],
    channels: [finitomata: [connection: :conn]]
  ]
