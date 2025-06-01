defmodule Telemetria.Backend.Persistomata do
  @moduledoc """
  The implementation of `Telemetria.Backend` for `:persistomata`.

  This module happens to appear in the documentation as an example
    of how one would approach building the highly customized versions
    of `Persistomata` from scratch.
  """

  @behaviour Telemetria.Backend

  require Logger

  @impl true
  @doc false
  def entry(block_id), do: block_id

  @impl true
  @doc false
  def update(block_id, _updates), do: block_id

  @impl true
  @doc """
  This function handles the main `telemetría` callback, reshapes the argument, and
    fires an `Antenna.event/3`, which in turn will be handled by `Persistomata.RamblaMatcher`.

  See the source code for details.
  """
  def return([:finitomata, :pool | _], _context), do: :ok

  def return(block_id, [%{} | _] = contextes) do
    contextes
    |> Enum.map(&reshape_context(block_id, &1))
    |> Enum.group_by(fn {id, type, _, _} -> {id, type} end)
    |> Enum.each(fn {{id, type}, events} ->
      id
      |> Persistomata.antenna()
      |> Antenna.event(
        [id, type, {id, type}],
        {:finitomata_bulk, Enum.map(events, &elem(&1, 3))}
      )
    end)
  end

  def return(block_id, %{} = context) do
    {id, type, fsm_name, event} = reshape_context(block_id, context)

    id
    |> Persistomata.antenna()
    |> Antenna.event(
      [id, type, {id, type}, {id, fsm_name}, {id, fsm_name, type}],
      {:finitomata, event}
    )
  end

  defp reshape_context(block_id, context) do
    {measurements, metadata} = Map.pop(context, :measurements, %{})

    {id, fini_id, fsm_name} =
      block_id
      |> Enum.reverse()
      |> id_from_event(metadata)
      |> extract_id()

    level = get_in(metadata, [:context, :options, :level])
    group = get_in(metadata, [:context, :options, :group])

    args =
      metadata.args
      |> Keyword.values()
      |> Enum.map(fn
        %Finitomata.State{current: state} -> {:->, state}
        other -> other
      end)

    {type, mfa} =
      with {:unknown, %{function: {f, a}, module: m}} <- {:unknown, metadata.env} do
        {
          extract_type(f, metadata.result, args),
          %{module: m, function: f, arity: a, capture: Function.capture(m, f, a)}
        }
      end

    event = %{
      id: id,
      fini_id: fini_id,
      fini_name: fsm_name,
      level: level,
      type: type,
      group: group,
      node: node(),
      mfa: mfa.capture,
      args: args,
      result: metadata.result,
      now: System.os_time(),
      times: measurements.system_time
    }

    type = elem(type, 0)

    {id, type, fsm_name, event}
  end

  @impl true
  @doc false
  def exit(_block_id), do: :ok

  @impl true
  @doc false
  def reshape(updates), do: updates

  defp extract_id(nil), do: nil

  defp extract_id({mod, name}) do
    with ["Finitomata" | ok] <- Module.split(mod),
         [_ | _] = fini_id <- Enum.slice(ok, 0..-2//1),
         [_ | _] = id <- List.delete_at(fini_id, -1),
         do: {Module.concat(id), Module.concat(fini_id), name},
         else: (_ -> {Persistomata.id(), Persistomata.finitomata(Persistomata.id()), name})
  end

  defp id_from_event([:safe_on_enter | _mod], metadata),
    do: get_in(metadata, [:args, :arg_1, Access.key!(:name), Access.elem(2)])

  defp id_from_event([:safe_on_exit | _mod], metadata),
    do: get_in(metadata, [:args, :arg_1, Access.key!(:name), Access.elem(2)])

  defp id_from_event([:safe_on_failure | _mod], metadata),
    do: get_in(metadata, [:args, :arg_2, Access.key!(:name), Access.elem(2)])

  defp id_from_event([:safe_on_fork | _mod], metadata),
    do: get_in(metadata, [:args, :arg_1, Access.elem(2)])

  defp id_from_event([:safe_on_start | _mod], metadata),
    do: get_in(metadata, [:args, :arg_0, :name, Access.elem(2)])

  defp id_from_event([:safe_on_terminate | _mod], metadata),
    do: get_in(metadata, [:args, :arg_0, Access.key!(:name), Access.elem(2)])

  defp id_from_event([:safe_on_timer | _mod], metadata),
    do: get_in(metadata, [:args, :arg_1, Access.key!(:name), Access.elem(2)])

  defp id_from_event([:safe_on_transition | _mod], metadata),
    do: get_in(metadata, [:args, :arg_0, Access.elem(2)])

  defp id_from_event([other | _mod], _metadata),
    do: tap(nil, fn nil -> Logger.warning("[🎁] Unexpected transition: " <> inspect(other)) end)

  @spec extract_type(atom(), atom() | tuple(), [term()]) ::
          {:pure, boolean()}
          | {:init, Finitomata.State.payload()}
          | {:mutating, Finitomata.State.payload(), Finitomata.State.payload()}
          | {:errored, :init | :transition, any()}
  defp extract_type(fun, result, args)
  defp extract_type(:safe_on_enter, _ok, [state, _]), do: {:state_changed, state}

  defp extract_type(:safe_on_start, {:stop, reason}, _payload), do: {:errored, :init, reason}
  defp extract_type(:safe_on_start, {_, payload}, _payload), do: {:init, payload}
  defp extract_type(:safe_on_start, _, [_, payload]), do: {:init, payload}

  defp extract_type(:safe_on_timer, :ok, _), do: {:pure, true}
  defp extract_type(:safe_on_timer, {:reschedule, _}, _), do: {:pure, true}
  defp extract_type(:safe_on_timer, {:ok, payload}, [_, %{payload: payload}]), do: {:pure, false}

  defp extract_type(:safe_on_timer, {:ok, new_payload}, [_, %{payload: old_payload}]),
    do: {:mutating, old_payload, new_payload}

  defp extract_type(:safe_on_timer, {:transition, _, payload}, [_, %{payload: payload}]),
    do: {:pure, false}

  defp extract_type(:safe_on_timer, {:transition, _, new_payload}, [_, %{payload: old_payload}]),
    do: {:mutating, old_payload, new_payload}

  defp extract_type(:safe_on_transition, {:ok, _, payload}, [_, _, _, _, payload]),
    do: {:pure, false}

  defp extract_type(:safe_on_transition, {:ok, _, new_payload}, [_, _, _, _, old_payload]),
    do: {:mutating, old_payload, new_payload}

  defp extract_type(:safe_on_transition, {:error, error}, _), do: {:errored, :transition, error}
  defp extract_type(_, _, _), do: {:pure, true}
end
