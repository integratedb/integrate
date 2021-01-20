defmodule Integrate.Validate do
  @moduledoc """
  Shared validation logic.
  """

  alias Ecto.Changeset

  @identifier_exp ~r/^[a-zA-Z_]{1}\w{0,63}$/
  @namespace_exp ~r/^\w{1,32}$/

  def identifier(changeset, field) do
    changeset
    |> Changeset.validate_format(field, @identifier_exp)
  end

  def validate_name(changeset, field) do
    changeset
    |> Changeset.validate_format(field, @namespace_exp)
  end

  def normalise_name(changeset, field) do
    changeset
    |> Changeset.update_change(field, &downcase_and_trim/1)
  end

  defp downcase_and_trim(nil), do: nil

  defp downcase_and_trim(value) do
    value
    |> String.downcase()
    |> String.trim()
  end

  def validate_and_downcase_namespace(value) when is_binary(value) do
    case String.match?(value, @namespace_exp) do
      true ->
        String.downcase(value)

      false ->
        raise "Invalid namespace -- must match `#{Regex.source(@namespace_exp)}`."
    end
  end

  def starts_with_same_schema_name(changeset, field) do
    changeset
    |> Changeset.validate_change(field, &validate_same_schema_name/2)
  end

  defp validate_same_schema_name(_, nil), do: []
  defp validate_same_schema_name(_, []), do: []

  defp validate_same_schema_name(field, [head | tail]) do
    [schema_name, _] = String.split(head, ".")

    case Enum.find(tail, &does_not_match_schema_name(&1, schema_name)) do
      nil ->
        []

      path ->
        msg = "Path alternatives `#{head}` and `#{path}` must share the same schema."

        [{field, msg}]
    end
  end

  defp does_not_match_schema_name(path, schema_name) do
    case String.split(path, ".") do
      [^schema_name, _] ->
        false

      _ ->
        true
    end
  end
end
