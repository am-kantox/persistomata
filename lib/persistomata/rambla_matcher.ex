defmodule Persistomata.RamblaMatcher do
  @moduledoc """
  This module happens to appear in the documentation as an example
    of how one would approach building the highly customized versions
    of `Persistomata` from scratch.

  `Telemetria.Backend.Persistomata` would have `telemetría` events emitted on 
    all the state changes. Here we subscribe to both `:finitomata` and 
    `:finitomata_bulk` events (either of them would be emitted depending
    on `config :telemetria, throttle: %{MyApp.MyFinitomata => {1_000, :all}}`
    setting.)
  """

  use GenServer

  require Antenna

  @behaviour Antenna.Matcher

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  @doc false
  def init(opts), do: {:ok, opts, {:continue, :rambla}}

  @impl GenServer
  @doc "In this callback we assign matchers"
  def handle_continue(:rambla, state) do
    id = Keyword.get(state, :id)

    Antenna.match(
      Persistomata.antenna(id),
      {:finitomata, _},
      Persistomata.RamblaMatcher,
      channels: [:init, :state_changed, :mutating]
    )

    Antenna.match(
      Persistomata.antenna(id),
      {:finitomata_bulk, _},
      Persistomata.RamblaMatcher,
      channels: [:init, :state_changed, :mutating]
    )

    {:noreply, state}
  end

  @impl Antenna.Matcher
  @doc "Handlers simply route the message(s) to `Rambla` instance"
  def handle_match(channel, {:finitomata, %{} = event}) do
    Rambla.publish(:finitomata, transform_event(channel, event))
  end

  def handle_match(channel, {:finitomata_bulk, events}) do
    Rambla.publish(:finitomata, Enum.map(events, &transform_event(channel, &1)))
  end

  defp transform_event(channel, event) do
    with module <- event.group,
         table <- Macro.underscore(module),
         times <- event.times,
         timestamp <- Keyword.get(times, :system),
         monotonic <- Keyword.get(times, :monotonic),
         unique_integer <- Keyword.get(times, :unique_integer) do
      {type, payload} =
        case event.type do
          {:init, payload} -> {:init, %{value: payload}}
          {:state_changed, state} -> {:state, %{state: state}}
          {:mutating, _, payload} -> {:value, %{value: payload}}
        end

      payload =
        with true <- function_exported?(module, :encode, 1),
             {:ok, result} <- module.encode(payload),
             do: result,
             else: (_ -> {:json, naive_encode(payload)})

      %{
        table: "`#{table}`",
        message: %{
          monotonic: monotonic,
          unique_integer: unique_integer,
          id: event.id,
          name: event.fini_name,
          channel: channel,
          type: type,
          node: event.node,
          timestamp: timestamp,
          payload: payload
        }
      }
    end
  end

  defp naive_encode(payload)

  cond do
    match?({:module, _}, Code.ensure_compiled(Jason.Encoder)) ->
      defp naive_encode(%_{} = payload) do
        case Jason.Encoder.impl_for(payload) do
          nil ->
            payload |> Map.from_struct() |> naive_encode()

          module ->
            opts =
              payload |> Map.get(:__meta__, %{}) |> get_in([:encode_options]) |> Kernel.||([])

            module.encode(payload, opts)
        end
      end

    match?({:module, _}, Code.ensure_compiled(JSON.Encoder)) ->
      defp naive_encode(%_{} = payload) do
        case JSON.Encoder.impl_for(payload) do
          nil ->
            payload |> Map.from_struct() |> naive_encode()

          module ->
            opts =
              payload |> Map.get(:__meta__, %{}) |> get_in([:encode_options]) |> Kernel.||([])

            module.encode(payload, opts)
        end
      end

    true ->
      defp naive_encode(%struct{} = payload) do
        require Logger

        Logger.warning(
          "[🎁] encoding struct ‹" <>
            inspect(struct) <> "› as a map, consider implementing the encoder"
        )

        payload |> Map.from_struct() |> naive_encode()
      end
  end

  defp naive_encode(%{} = payload) do
    Map.new(payload, fn {k, v} -> {k, naive_encode(v)} end)
  end

  defp naive_encode(payload) when is_list(payload) do
    if Keyword.keyword?(payload),
      do: payload |> Map.new() |> naive_encode(),
      else: Enum.map(payload, &naive_encode/1)
  end

  defp naive_encode(payload)
       when is_nil(payload) or is_boolean(payload) or is_number(payload) or is_binary(payload),
       do: payload

  defp naive_encode(payload) when is_atom(payload), do: Atom.to_string(payload)

  defp naive_encode(payload) do
    case String.Chars.impl_for(payload) do
      nil -> inspect(payload)
      module -> module.to_string(payload)
    end
  end
end
