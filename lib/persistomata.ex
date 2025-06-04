defmodule Persistomata do
  @moduledoc """
  Documentation for `Persistomata`.
  """

  @id Application.compile_env(:persistomata, :id, Persistomata)

  @doc false
  def id, do: @id

  @doc false
  def antenna(id), do: Module.concat(id, Antenna)
  @doc false
  def finitomata(id), do: Module.concat(id, Finitomata)
  @doc false
  def rambla(id), do: Module.concat(id, Rambla)

  # Supervision tree
  use Supervisor

  @doc """
  Starts the `Persistomata` matcher tree for the `id` given. 
  """
  @doc section: :setup
  @spec start_link([{:id, atom()}]) :: Supervisor.on_start()
  def start_link(init_arg \\ []) do
    init_arg =
      if Keyword.keyword?(init_arg), do: Keyword.get_lazy(init_arg, :id, &id/0), else: init_arg

    Supervisor.start_link(__MODULE__, init_arg, name: init_arg)
  end

  @impl Supervisor
  @doc false
  def init(id) do
    maybe_start()
    |> Kernel.++([
      {Infinitomata, finitomata(id)},
      {Antenna, antenna(id)},
      {Rambla, name: rambla(id)},
      {Persistomata.RamblaMatcher, id: id}
    ])
    |> Supervisor.init(strategy: :one_for_one)
  end

  :rambla
  |> Application.compile_env(:clickhouse, [])
  |> Keyword.fetch(:connections)
  |> case do
    {:ok, _connections} -> defp maybe_start, do: [Persistomata.Pillar]
    _ -> defp maybe_start, do: []
  end
end
