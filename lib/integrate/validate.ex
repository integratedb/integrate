defmodule Integrate.Validate do
  @moduledoc """
  Shared validation logic.
  """

  alias Ecto.Changeset

  @name_exp ~r/^[-\w]{1,64}$/

  def validate_name(changeset, field) do
    changeset
    |> Changeset.validate_format(field, @name_exp)
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
end
