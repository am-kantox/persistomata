defmodule Persistomata.RamblaEncoder do
  @moduledoc """
  The implementation of this behaviour might be used as an encoder/decoder
    of `Finitomata.State.payload()` to store/load it with `Persistomata`.
  """

  @doc """
  The callback used to encode the value to the JSON-like representation
  """
  @callback encode(payload :: Finitomata.State.payload()) :: {:ok, term()} | {:error, term()}

  @doc """
  The callback used to decode the value from the JSON-like representation
  """
  @callback decode(json :: term()) :: {:ok, Finitomata.State.payload()} | {:error, term()}
end
