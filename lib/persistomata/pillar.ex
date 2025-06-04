:rambla
|> Application.compile_env(:clickhouse, [])
|> Keyword.fetch(:connections)
|> case do
  {:ok, connections} ->
    defmodule Persistomata.Pillar do
      @moduledoc """
      Helpers to deal with the CLickhouse backend
      """
      @connection_strings Keyword.values(connections)

      use Pillar,
        connection_strings: @connection_strings,
        name: __MODULE__,
        pool_size: 15,
        # Time to wait for a connection from the pool
        pool_timeout: 10_000,
        # Default query timeout
        timeout: 30_000

      def all(module) do
        table = Macro.underscore(module)

        select("""
        SELECT name, argMax(payload.state, timestamp) as state
        FROM `#{table}`
        WHERE type = 'state'
        GROUP BY name
        """)
      end

      def active(module) do
        table = Macro.underscore(module)

        with {:ok, active} <-
               select("""
               SELECT name
               FROM
               (
                 SELECT
                   name,
                   argMax(payload.state, timestamp) as state
                 FROM `#{table}`
                 WHERE type = 'state'
                 GROUP BY name
               )
               WHERE state != '*'
               """),
             do: {:ok, Enum.map(active, &Map.fetch!(&1, "name"))}
      end

      def load(module, name) do
        table = Macro.underscore(module)

        with {:ok, [%{"payload.value" => value}]} <-
               select("""
               SELECT payload.value
               FROM `#{table}`
               WHERE type = 'value' AND name = '#{name}'
               ORDER BY timestamp DESC, node DESC, unique_integer DESC
               LIMIT 1
               """),
             {:ok, value} <- decode(value),
             {:ok, [%{"payload.state" => state}]} <-
               select("""
               SELECT payload.state
               FROM `#{table}`
               WHERE type = 'state' AND name = '#{name}'
               ORDER BY timestamp DESC, node DESC, unique_integer DESC
               LIMIT 1
               """),
             do: {:ok, %{state: state, value: value}}
      end

      defp atomize_keys(%{} = data),
        do: Map.new(data, fn {k, v} -> {String.to_existing_atom(k), atomize_keys(v)} end)

      defp atomize_keys(data) when is_list(data),
        do: Enum.map(data, &atomize_keys/1)

      defp atomize_keys(any), do: any

      defp decode(%{} = data), do: {:ok, atomize_keys(data)}

      cond do
        match?({:module, _}, Code.ensure_compiled(Jason)) ->
          defp decode(data) when is_binary(data), do: Jason.decode(data, keys: :atoms)

        match?({:module, _}, Code.ensure_compiled(JSON)) ->
          defp decode(data) when is_binary(data) do
            with {:ok, result} <- JSON.decode(data), do: {:ok, atomize_keys(result)}
          end
      end
    end

  _ ->
    :ok
end
