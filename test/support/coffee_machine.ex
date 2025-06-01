defmodule Persistomata.Test.CoffeeMachine do
  @moduledoc false

  @fsm """
    idle --> |power_on!| ready
    ready --> |insert_money| brewing
    brewing --> |finish| done
    done --> |take_coffee| ready
    ready --> |power_off| off
    done --> |power_off| off
  """

  use Finitomata, fsm: @fsm, auto_terminate: true, timer: 1_000, listener: :mox

  def start_supervised(id, name) do
    Infinitomata.start_fsm(id, name, __MODULE__, 0)
  end

  def power_on(id, name), do: Infinitomata.transition(id, name, :power_on)
  def power_off(id, name), do: Infinitomata.transition(id, name, :power_off)

  def insert_money(id, name, amount \\ 1),
    do: Infinitomata.transition(id, name, {:insert_money, amount})

  def finish(id, name), do: Infinitomata.transition(id, name, :finish)
  def take_coffee(id, name), do: Infinitomata.transition(id, name, :take_coffee)

  @impl Finitomata
  def on_timer(:brewing, state), do: {:transition, :finish, state.payload}
  def on_timer(_not_brewing, _state), do: :ok

  def on_transition(:idle, :power_on, _payload, coffee_count) do
    {:ok, :ready, coffee_count}
  end

  def on_transition(:ready, :insert_money, _amount, coffee_count) do
    {:ok, :brewing, coffee_count}
  end

  def on_transition(:brewing, :finish, _payload, coffee_count) do
    {:ok, :done, coffee_count + 1}
  end

  def on_transition(:done, :take_coffee, _payload, coffee_count) do
    {:ok, :ready, coffee_count}
  end

  def on_transition(_any_state, :power_off, _payload, coffee_count) do
    {:ok, :idle, coffee_count}
  end
end
