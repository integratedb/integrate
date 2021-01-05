defmodule Integrate.StakeholdersTest do
  use Integrate.DataCase

  alias Integrate.Stakeholders

  describe "stakeholders" do
    setup [:create_user]

    alias Integrate.Stakeholders.Stakeholder

    @valid_attrs %{name: "some-name"}
    @update_attrs %{name: "some-updated-name"}
    @invalid_attrs %{name: nil}

    def stakeholder_fixture(user, attrs \\ %{}) do
      {:ok, stakeholder} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Map.put(:user_id, user.id)
        |> Stakeholders.create_stakeholder()

      stakeholder
    end

    test "list_stakeholders/0 returns all stakeholders", %{user: user} do
      stakeholder = stakeholder_fixture(user)
      assert Stakeholders.list_stakeholders() == [stakeholder]
    end

    test "get_stakeholder!/1 returns the stakeholder with given id", %{user: user} do
      stakeholder = stakeholder_fixture(user)
      assert Stakeholders.get_stakeholder!(stakeholder.id) == stakeholder
    end

    test "create_stakeholder/1 with valid data creates a stakeholder", %{user: user} do
      attrs = Map.put(@valid_attrs, :user_id, user.id)
      assert {:ok, %Stakeholder{} = stakeholder} = Stakeholders.create_stakeholder(attrs)
      assert stakeholder.name == "some-name"
    end

    test "create_stakeholder/1 with invalid data returns error changeset", %{user: user} do
      attrs = Map.put(@invalid_attrs, :user_id, user.id)
      assert {:error, %Ecto.Changeset{}} = Stakeholders.create_stakeholder(attrs)
    end

    test "update_stakeholder/2 with valid data updates the stakeholder", %{user: user} do
      stakeholder = stakeholder_fixture(user)
      assert {:ok, %Stakeholder{} = stakeholder} = Stakeholders.update_stakeholder(stakeholder, @update_attrs)
      assert stakeholder.name == "some-updated-name"
    end

    test "update_stakeholder/2 with invalid data returns error changeset", %{user: user} do
      stakeholder = stakeholder_fixture(user)
      assert {:error, %Ecto.Changeset{}} = Stakeholders.update_stakeholder(stakeholder, @invalid_attrs)
      assert stakeholder == Stakeholders.get_stakeholder!(stakeholder.id)
    end

    test "delete_stakeholder/1 deletes the stakeholder", %{user: user} do
      stakeholder = stakeholder_fixture(user)
      assert {:ok, %Stakeholder{}} = Stakeholders.delete_stakeholder(stakeholder)
      assert_raise Ecto.NoResultsError, fn -> Stakeholders.get_stakeholder!(stakeholder.id) end
    end

    test "change_stakeholder/1 returns a stakeholder changeset", %{user: user} do
      stakeholder = stakeholder_fixture(user)
      assert %Ecto.Changeset{} = Stakeholders.change_stakeholder(stakeholder)
    end
  end
end
