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

  @doc "The hook to inject stuff into generated implementations"
  defmacro __before_compile__(_env) do
    module = __CALLER__.module
    fsm = Module.get_attribute(module, :__config__)
    entry = fsm.entry
    entry_state = Enum.find(fsm.fsm, &match?(%{event: ^entry}, &1)).to

    quote generated: true, location: :keep do
      defimpl Finitomata.Persistency.Persistable do
        @moduledoc """
        Implementation of `Finitomata.Persistency.Persistable` for `#{inspect(unquote(module))}`.
        """

        require Logger

        @doc "Loads the entity from some external storage"
        def load(data, opts \\ [])

        def load(%unquote(module){} = data, opts) do
          case Keyword.fetch(opts, :id) do
            {:ok, {:via, Registry, {_, name}}} ->
              case Persistomata.Pillar.load(unquote(module), to_string(name)) do
                {:ok, %{state: state, value: value}} ->
                  {:loaded, {state, struct!(unquote(module), value)}}

                {:error, :no_record} ->
                  {:created, {unquote(entry_state), data}}

                error ->
                  Logger.error(
                    "Error loading value for ‹#{name}› " <>
                      "from ‹#{Persistomata.Pillar.table_name(:view, unquote(module))}›: " <>
                      inspect(error)
                  )

                  {:failed, {unquote(entry_state), data}}
              end

            :error ->
              {:created, {unquote(entry_state), data}}
          end
        end

        @doc "Persists the transitioned entity to some external storage"
        def store(_data, _info), do: :ok

        @doc "Persists the error happened while an attempt to transition the entity"
        def store_error(data, reason, info),
          do: Logger.debug("STORE ERROR: " <> inspect(data: data, reason: reason, info: info))
      end
    end
  end

  @doc false
  defmacro __using__(opts \\ []) do
    quote generated: true, location: :keep do
      @before_compile Persistomata

      @persistomata_opts unquote(opts)

      @doc false
      def persistomata_opts, do: @persistomata_opts
    end
  end
end
