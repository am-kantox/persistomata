import Config

level =
  case Mix.env() do
    :test -> :warning
    :finitomata -> :debug
    :ci -> :debug
    :prod -> :warning
    :dev -> :info
  end

config :logger,
  level: level,
  default_handler: [level: level],
  default_formatter: [colors: [info: :magenta]],
  compile_time_purge_matching: [[level_lower_than: level]]

config :finitomata, :telemetria, true

config :telemetria,
  backend: Telemetria.Backend.Persistomata,
  throttle: %{Persistomata.Test.Turnstile => {1_000, :all}},
  purge_level: :debug,
  level: :info,
  events: []

config :rambla,
  clickhouse: [
    # connections: [conn: "https://user:password@localhost:8123/some_database"],
    connections: [conn: "http://default:password@localhost:8123/default"],
    channels: [finitomata: [connection: :conn]]
  ]
