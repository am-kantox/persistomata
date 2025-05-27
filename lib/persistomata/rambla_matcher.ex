defmodule Persistomata.RamblaMatcher do
  @moduledoc false

  use GenServer

  require Antenna

  @behaviour Antenna.Matcher

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts), do: {:ok, opts, {:continue, :rambla}}

  @impl GenServer
  def handle_continue(:rambla, state) do
    id = Keyword.get(state, :id)

    Antenna.match(
      Persistomata.antenna(id),
      {:finitomata, _},
      Persistomata.RamblaMatcher,
      channels: [:init, :state_changed, :mutating]
    )

    {:noreply, state}
  end

  @impl Antenna.Matcher
  def handle_match(channel, {:finitomata, %{} = event}) do
    with {:finitomata, module} <- event.group,
         table <- Macro.underscore(module),
         timestamp <- get_in(event, [:times, :system]),
         monotonic <- get_in(event, [:times, :unique_integer]) do
      {type, payload} =
        case event.type do
          {:init, payload} -> {:init, payload}
          {:state_changed, state} -> {:state, state}
          {:mutating, _, payload} -> {:value, payload}
        end

      payload =
        with true <- function_exported?(module, :encode, 1),
             {:ok, result} <- module.encode(payload),
             do: result,
             else: (_ -> payload)

      message =
        %{
          table: "`#{table}`",
          message: %{
            monotonic: monotonic,
            id: event.id,
            name: event.fini_name,
            channel: channel,
            type: type,
            payload: payload,
            node: event.node,
            timestamp: timestamp
          }
        }

      Rambla.publish(:finitomata, message)
    end
  end
end
