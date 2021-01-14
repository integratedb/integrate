defmodule Integrate.Util do
  @moduledoc """
  Shared utility functions.
  """

  def to_string_keys(value) when is_map(value) do
    value
    |> Enum.map(&ensure_string_key/1)
    |> Enum.into(%{})
  end

  def to_string_keys(value) when is_list(value) do
    value
    |> Enum.map(&to_string_keys/1)
  end

  def to_string_keys(value), do: value

  defp ensure_string_key({key, value}) do
    {to_string(key), to_string_keys(value)}
  end
end
