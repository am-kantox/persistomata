:rambla
|> Application.compile_env(:clickhouse, [])
|> Keyword.fetch(:connections)
|> case do
  {:ok, connections} ->
    defmodule Persistomata.Pillar do
      @moduledoc """
      Helpers to deal with the CLickhouse backend
      """
      require Logger

      @connection_strings Keyword.values(connections)

      use Pillar,
        connection_strings: @connection_strings,
        name: __MODULE__,
        pool_size: 15,
        # Time to wait for a connection from the pool
        pool_timeout: 10_000,
        # Default query timeout
        timeout: 30_000

      @doc false
      def table_name(:original, module) when is_atom(module),
        do: module |> Macro.underscore()

      def table_name(:latest, module) when is_atom(module),
        do: :original |> table_name(module) |> Kernel.<>("/__latest__")

      def table_name(:view, module) when is_atom(module),
        do: :latest |> table_name(module) |> Kernel.<>("/__view__")

      def all(module, opts \\ []) do
        table = table_name(:view, module)

        limit =
          case Keyword.get(opts, :limit) do
            limit when is_integer(limit) -> "LIMIT #{limit}"
            _ -> ""
          end

        # [AM] [TODO] Add regexp as `name: {:re, ~r/.../}`
        where =
          case {Keyword.get(opts, :name), Keyword.get(opts, :active?, false)} do
            {nil, true} -> "WHERE payload.state != '*'"
            {nil, false} -> ""
            {name, true} -> "WHERE name = '#{name}' AND payload.state != '*'"
            {name, false} -> "WHERE name = '#{name}'"
          end

        select("""
        SELECT *
        FROM `#{table}`
        FINAL
        #{where}
        #{limit}
        """)
      end

      def load(module, name) do
        table = table_name(:view, module)

        with {:ok, [%{"payload" => %{"value" => value, "state" => state}}]} <-
               select("""
               SELECT payload
               FROM `#{table}`
               FINAL
               WHERE name = '#{name}' AND payload.state != '*'
               """),
             {:ok, value} <- decode(module, value) do
          {:ok, %{state: String.to_existing_atom(state), value: value}}
        else
          {:ok, []} -> {:error, :no_record}
          {:error, error} -> {:error, error}
        end
      end

      def find(module, filter, active? \\ true) do
        table = Macro.underscore(module)
        # AM [FIXME]
        filter_string =
          filter |> Enum.map(fn {k, v} -> "payload.value.#{k} = #{v}" end) |> Enum.join(" AND ")

        maybe_restrict =
          if active? do
            """
              INNER JOIN (
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
              ) AS `#{table}/__active__`
              ON `#{table}`.name = `#{table}/__active__`.name
            """
          end

        with {:ok, [%{"payload" => %{"value" => _value}} | _] = result} <-
               select(
                 """
                 SELECT timestamp, name, payload
                 FROM `#{table}`
                 #{maybe_restrict}
                 WHERE type = 'value' AND (#{filter_string})
                 ORDER BY timestamp DESC, node DESC, unique_integer DESC
                 """
                 |> tap(&IO.puts/1)
               ) do
          {:ok,
           Enum.flat_map(result, fn %{
                                      "payload" => %{"value" => value},
                                      "timestamp" => timestamp,
                                      "name" => name
                                    } ->
             case decode(module, value) do
               {:ok, value} -> [%{name: name, timestamp: timestamp, value: value}]
               error -> tap([], fn _ -> Logger.warning("Error decoding: " <> inspect(error)) end)
             end
           end)}
        end
      end

      defp atomize_keys(%{} = data),
        do: Map.new(data, fn {k, v} -> {String.to_existing_atom(k), atomize_keys(v)} end)

      defp atomize_keys(data) when is_list(data),
        do: Enum.map(data, &atomize_keys/1)

      defp atomize_keys(any), do: any

      defp decode(module, data) do
        with true <- function_exported?(module, :decode, 1),
             {:ok, result} <- module.decode(data),
             do: result,
             else: (_ -> do_decode(data))
      end

      defp do_decode(%{} = data), do: {:ok, atomize_keys(data)}

      cond do
        match?({:module, _}, Code.ensure_compiled(Jason)) ->
          defp do_decode(data) when is_binary(data), do: Jason.decode(data, keys: :atoms)

        match?({:module, _}, Code.ensure_compiled(JSON)) ->
          defp do_decode(data) when is_binary(data) do
            with {:ok, result} <- JSON.decode(data), do: {:ok, atomize_keys(result)}
          end

        true ->
          defp do_decode(data) when is_binary(data), do: {:ok, data}
      end

      defp do_decode(invalid), do: {:error, invalid}
    end

    defmodule Persistomata.Pillar.Migrator do
      @moduledoc false
      @connection_string connections |> Keyword.values() |> List.first()
      def run do
        if is_nil(@connection_string), do: raise("Malformed connection string(s)")
        Pillar.Migrations.migrate(Pillar.Connection.new(@connection_string))
      end
    end

  _ ->
    :ok
end
