defmodule Integrate.Validate do
  @moduledoc """
  Shared validation logic.
  """

  alias Ecto.Changeset

  @namespace_exp ~r/^\w{1,32}$/

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
end
