defmodule Integrate.SpecificationTest do
  use Integrate.DataCase

  alias Integrate.Specification

  describe "specification" do
    setup [:create_user, :create_stakeholder]

    alias Integrate.Specification.Spec

    @valid_attrs %{
      match: [],
      type: Spec.types(:claims)
    }
    @update_attrs %{
      match: [],
      type: Spec.types(:notifications)
    }
    @invalid_attrs %{
      match: nil,
      type: "lala"
    }

    def spec_fixture(stakeholder, attrs \\ %{}) do
      attrs =
        attrs
        |> Enum.into(@valid_attrs)

      {:ok, spec} = Specification.create_spec(stakeholder, attrs)
      spec
    end

    test "list_specs/0 returns all specs", %{stakeholder: stakeholder} do
      spec = spec_fixture(stakeholder)
      assert Specification.list_specs() == [spec]
    end

    test "get_spec!/1 returns the spec with given id", %{stakeholder: stakeholder} do
      spec = spec_fixture(stakeholder)
      assert Specification.get_spec!(spec.id) == spec
    end

    test "create_spec/1 with valid data creates a spec", %{stakeholder: stakeholder} do
      assert {:ok, %Spec{} = spec} = Specification.create_spec(stakeholder, @valid_attrs)

      assert spec.type == Spec.types(:claims)
    end

    test "create_spec/1 with invalid data returns error changeset", %{stakeholder: stakeholder} do
      assert {:error, %Ecto.Changeset{}} = Specification.create_spec(stakeholder, @invalid_attrs)
    end

    test "update_spec/2 with valid data updates the spec", %{stakeholder: stakeholder} do
      spec = spec_fixture(stakeholder)

      assert {:ok, %Spec{} = spec} = Specification.update_spec(spec, @update_attrs)

      assert spec.type == Spec.types(:notifications)
    end

    test "update_spec/2 with invalid data returns error changeset", %{stakeholder: stakeholder} do
      spec = spec_fixture(stakeholder)
      assert {:error, %Ecto.Changeset{}} = Specification.update_spec(spec, @invalid_attrs)
      assert spec == Specification.get_spec!(spec.id)
    end

    test "delete_spec/1 deletes the spec", %{stakeholder: stakeholder} do
      spec = spec_fixture(stakeholder)
      assert {:ok, %Spec{}} = Specification.delete_spec(spec)
      assert_raise Ecto.NoResultsError, fn -> Specification.get_spec!(spec.id) end
    end

    test "change_spec/1 returns a spec changeset", %{stakeholder: stakeholder} do
      spec = spec_fixture(stakeholder)
      assert %Ecto.Changeset{} = Specification.change_spec(spec)
    end
  end
end
