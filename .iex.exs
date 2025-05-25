"~/.iex.code/*.ex" |> Path.expand() |> Path.wildcard() |> Enum.each(&Code.require_file/1)
global_settings = Path.expand("~/.iex.exs")
if File.exists?(global_settings), do: Code.eval_file(global_settings)

# IEx.configure(inspect: [limit: :infinity])

require Antenna

id = Persistomata.id() |> Persistomata.finitomata()
Persistomata.start_link()
