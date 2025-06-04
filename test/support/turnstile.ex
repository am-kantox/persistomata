defmodule Persistomata.Test.Turnstile do
  @moduledoc false

  @fsm """
    idle --> |close!| closed
    closed --> |coin| opened
    opened --> |coin| opened
    opened --> |walk| opened,closed
    closed --> |off| inactive
  """

  use Persistomata

  use Finitomata,
    fsm: @fsm,
    auto_terminate: true,
    persistency: Finitomata.Persistency.Protocol,
    listener: :mox

  @derive {Jason.Encoder, only: [:coins]}
  defstruct coins: 0

  def start_supervised(id, name \\ nil) do
    name = with nil <- name, do: UUID.uuid4()

    with {:ok, pid} <- Infinitomata.start_fsm(id, name, __MODULE__, %__MODULE__{}),
         do: {:ok, pid, name}
  end

  @table_name Macro.underscore(__MODULE__)
  def table_name, do: @table_name

  def walk(id, name, number \\ 1), do: Infinitomata.transition(id, name, {:walk, number})
  def coin(id, name, number \\ 1), do: Infinitomata.transition(id, name, {:coin, number})
  def off(id, name), do: Infinitomata.transition(id, name, :off)

  @impl Finitomata

  def on_transition(:closed, :coin, number, %{coins: coins} = state) do
    {:ok, :opened, %{state | coins: coins + number}}
  end

  def on_transition(:closed, :off, _payload, %{coins: 0} = state) do
    {:ok, :inactive, state}
  end

  def on_transition(:opened, :coin, number, %{coins: coins} = state) do
    {:ok, :opened, %{state | coins: coins + number}}
  end

  def on_transition(:opened, :walk, coins, %{coins: coins} = state) do
    {:ok, :closed, %{state | coins: 0}}
  end

  def on_transition(:opened, :walk, number, %{coins: coins} = state) when number < coins do
    {:ok, :opened, %{state | coins: coins - number}}
  end

  def on_transition(:opened, :walk, number, %{coins: coins}) when number > coins do
    {:error, :not_enough_funds}
  end

  # @behaviour Persistomata.RamblaEncoder

  # @impl Persistomata.RamblaEncoder
  # def decode(%{coins: coins}), do: {:ok, coins}
  # def decode(%{state: state}), do: {:ok, {:state, state}}
  # def decode(%{} = payload), do: {:ok, payload}
  # def decode(other), do: {:error, other}

  # @impl Persistomata.RamblaEncoder
  # def encode(%{} = payload), do: {:ok, {:json, payload}}
  # def encode(payload) when is_integer(payload), do: {:ok, {:json, %{coins: payload}}}
  # def encode(payload) when is_atom(payload), do: {:ok, {:json, %{state: payload}}}
  # def encode(other), do: {:error, other}
end
