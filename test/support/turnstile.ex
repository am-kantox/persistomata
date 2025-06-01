defmodule Persistomata.Test.Turnstile do
  @moduledoc false

  @fsm """
    idle --> |close!| closed
    closed --> |coin| opened
    opened --> |coin| opened
    opened --> |walk| opened,closed
    closed --> |off| inactive
  """

  use Finitomata, fsm: @fsm, auto_terminate: true, listener: :mox

  def start_supervised(id, name) do
    Infinitomata.start_fsm(id, name, __MODULE__, 0)
  end

  def walk(id, name, number \\ 1), do: Infinitomata.transition(id, name, {:walk, number})
  def coin(id, name, number \\ 1), do: Infinitomata.transition(id, name, {:coin, number})
  def off(id, name), do: Infinitomata.transition(id, name, :off)

  @impl Finitomata

  def on_transition(:closed, :coin, number, coins) do
    {:ok, :opened, coins + number}
  end

  def on_transition(:closed, :off, _payload, 0) do
    {:ok, :inactive, 0}
  end

  def on_transition(:opened, :coin, number, coins) do
    {:ok, :opened, coins + number}
  end

  def on_transition(:opened, :walk, coins, coins) do
    {:ok, :closed, 0}
  end

  def on_transition(:opened, :walk, number, coins) when number < coins do
    {:ok, :opened, coins - number}
  end

  def on_transition(:opened, :walk, number, coins) when number > coins do
    {:error, :not_enough_funds}
  end

  # @behaviour Persistomata.RamblaEncoder

  # @impl Persistomata.RamblaEncoder
  # def decode(%{coins: payload}), do: {:ok, payload}
  # def decode(other), do: {:error, other}

  # @impl Persistomata.RamblaEncoder
  # def encode(payload) when is_integer(payload), do: {:ok, {:json, %{coins: payload}}}
  # def encode(payload) when is_atom(payload), do: {:ok, {:json, %{state: payload}}}
  # def encode(other), do: {:error, other}
end
