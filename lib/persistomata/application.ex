defmodule Persistomata.Application do
  @moduledoc false

  use Elixir.Application

  @app_args Application.compile_env(:persistomata, :app_args, [])
  @pillar_migrations_path Application.compile_env(
                            :persistomata,
                            :pillar_migrations,
                            "priv/pillar_migrations"
                          )

  @impl Elixir.Application
  def start(_type, args) do
    args =
      if Keyword.keyword?(args),
        do: Keyword.merge(@app_args, args),
        else: Keyword.put(@app_args, :id, args)

    {children?, args} = Keyword.pop(args, :start_persistomata?, false)

    id =
      case Keyword.fetch(args, :id) do
        {:ok, id} -> id
        _ -> Persistomata.id()
      end

    children = if children?, do: [{Persistomata, id}], else: []

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl Application
  def start_phase(:persistomata_setup, _start_type, []) do
    # credo:disable-for-lines: 2 Credo.Check.Refactor.Nesting
    if Code.ensure_loaded?(Persistomata.Pillar.Migrator) and
         File.exists?(@pillar_migrations_path),
       do: Persistomata.Pillar.Migrator.run()

    :ok
  end

  def migrations_path, do: @pillar_migrations_path
end
