defmodule Integrate.Util do
  @moduledoc """
  Shared utility functions.
  """

  def coerce_atom_keys_to_string_keys(%{} = attrs) do
    attrs
    |> Enum.map(&ensure_string_key/1)
    |> Enum.into(%{})
  end

  defp ensure_string_key({k, v}) when is_binary(k) do
    {k, v}
  end

  defp ensure_string_key({k, v}) when is_atom(k) do
    {to_string(k), v}
  end
end
