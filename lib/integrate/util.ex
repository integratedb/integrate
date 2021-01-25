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

  def read_priv_file!(parts) do
    [:code.priv_dir(:integratedb) | parts]
    |> Path.join()
    |> File.read!()
  end

  def drop_matching(%{} = a, %{} = b) do
    a
    |> Enum.map(fn {k, v} ->
      keys =
        b
        |> Map.get(k, %{})
        |> Map.keys()

      {k, Map.drop(v, keys)}
    end)
    |> Enum.into(%{})
  end

  def take_matching(%{} = a, %{} = b) do
    a
    |> Enum.map(fn {k, v} ->
      keys =
        b
        |> Map.get(k, %{})
        |> Map.keys()

      {k, Map.take(v, keys)}
    end)
    |> Enum.into(%{})
  end
end
