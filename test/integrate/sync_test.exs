defmodule Integrate.SyncTest do
  use Integrate.DataCase

  alias Integrate.Repo
  alias Integrate.Util

  alias Integrate.Claims
  alias Integrate.Specification
  alias Integrate.SpecificationData

  defp set_spec(stakeholder, data) do
    {:ok, attrs} =
      data
      |> Util.to_string_keys()
      |> SpecificationData.validate_and_expand()

    Specification.set_spec(stakeholder, :claims, attrs)
  end

  def get_column_names(spec) do
    spec
    |> Claims.get_by_spec()
    |> Enum.reduce([], fn claim, acc ->
      claim.alternatives
      |> Enum.reduce(acc, fn claim_alt, acc ->
        claim_alt.columns
        |> Enum.reduce(acc, fn col, acc ->
          col.alternatives
          |> Enum.reduce(acc, fn col_alt, acc ->
            [col_alt.name | acc]
          end)
        end)
      end)
    end)
  end

  describe "sync specs" do
    setup [:create_user, :create_stakeholder]

    test "claims adapt to removed column", %{stakeholder: stakeholder} do
      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: ["*"]
          }
        ]
      }

      {:ok, %{spec: spec}} = set_spec(stakeholder, data)
      assert ["id", "inserted_at", "name", "updated_at"] = get_column_names(spec) |> Enum.sort()

      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos DROP COLUMN name")

      key = "spec-#{spec.id}"
      {:ok, %{^key => updated_spec}} = Specification.sync_specs()
      assert ["id", "inserted_at", "updated_at"] = get_column_names(updated_spec) |> Enum.sort()
    end

    test "claims adapt to added column", %{stakeholder: stakeholder} do
      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: ["*"]
          }
        ]
      }

      {:ok, %{spec: spec}} = set_spec(stakeholder, data)

      has_bar_column =
        spec
        |> get_column_names()
        |> Enum.member?("bar")

      refute has_bar_column

      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos ADD COLUMN bar VARCHAR(255)")

      key = "spec-#{spec.id}"
      {:ok, %{^key => updated_spec}} = Specification.sync_specs()

      has_bar_column =
        updated_spec
        |> get_column_names()
        |> Enum.member?("bar")

      assert has_bar_column
    end
  end
end
