defmodule Integrate.StakeholdersTest do
  use Integrate.DataCase

  alias Integrate.Stakeholders

  describe "stakeholders" do
    setup [:create_user]

    alias Integrate.Stakeholders.Stakeholder

    @valid_attrs %{name: "some_name"}
    @update_attrs %{name: "some_updated_name"}
    @invalid_attrs %{name: nil}

    def stakeholder_fixture(user, attrs \\ %{}) do
      attrs =
        attrs
        |> Enum.into(@valid_attrs)

      {:ok, %{stakeholder: stakeholder, db_user: db_user}} =
        Stakeholders.create_stakeholder(user, attrs)

      %{stakeholder: stakeholder, stakeholder_db_user: db_user}
    end

    test "list_stakeholders/0 returns all stakeholders", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)
      assert Stakeholders.list_stakeholders() == [stakeholder]
    end

    test "get_stakeholder!/1 returns the stakeholder with given id", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)
      assert Stakeholders.get_stakeholder!(stakeholder.id) == stakeholder
    end

    test "create_stakeholder/1 with valid data creates a stakeholder", %{user: user} do
      assert {:ok, %{stakeholder: %Stakeholder{} = stakeholder}} =
               Stakeholders.create_stakeholder(user, @valid_attrs)

      assert stakeholder.name == "some_name"
    end

    test "create_stakeholder/1 creates a db_user and returns its credentials", %{user: user} do
      assert {:ok, %{db_user: {user, password}}} =
               Stakeholders.create_stakeholder(user, @valid_attrs)

      assert user == "some_name"
      assert String.length(password) == 24
    end

    test "create_stakeholder/1 scopes the db_user to a synonymous ddl schema", %{user: user} do
      assert {:ok, %{stakeholder: %Stakeholder{name: name}}} =
               Stakeholders.create_stakeholder(user, @valid_attrs)

      query = "SELECT schema_name FROM information_schema.schemata where schema_name = $1"
      assert {:ok, %{rows: [[^name]], num_rows: 1}} = Repo.query(query, [name])
    end

    test "create_stakeholder/1 with invalid data returns error changeset", %{user: user} do
      assert {:error, :stakeholder, %Ecto.Changeset{}, _} =
               Stakeholders.create_stakeholder(user, @invalid_attrs)
    end

    test "update_stakeholder/2 with valid data updates the stakeholder", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)

      name = @update_attrs.name

      assert {:ok, %{stakeholder: %Stakeholder{name: ^name}}} =
               Stakeholders.update_stakeholder(stakeholder, @update_attrs)
    end

    test "update_stakeholder/2 renames the schema and user", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)

      name = @update_attrs.name

      assert {:ok, %{ddl_schema: ^name, db_user: {^name, _}}} =
               Stakeholders.update_stakeholder(stakeholder, @update_attrs)
    end

    test "update_stakeholder/2 generates a new db user password", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)

      assert {:ok, %{db_user: {_, password}}} =
               Stakeholders.update_stakeholder(stakeholder, @update_attrs)

      assert String.length(password) == 24
    end

    test "update_stakeholder/2 iff the name has changed", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)

      assert {:ok, %{db_user: {_, nil}}} =
               Stakeholders.update_stakeholder(stakeholder, %{name: stakeholder.name})
    end

    test "update_stakeholder/2 with invalid data returns error changeset", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)

      assert {:error, :stakeholder, %Ecto.Changeset{} = _, _} =
               Stakeholders.update_stakeholder(stakeholder, @invalid_attrs)

      assert stakeholder == Stakeholders.get_stakeholder!(stakeholder.id)
    end

    test "delete_stakeholder/1 deletes the stakeholder", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)
      assert {:ok, %{stakeholder: %Stakeholder{}}} = Stakeholders.delete_stakeholder(stakeholder)
      assert_raise Ecto.NoResultsError, fn -> Stakeholders.get_stakeholder!(stakeholder.id) end
    end

    test "delete_stakeholder/1 deletes the db user", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)
      assert {:ok, %{db_user: nil}} = Stakeholders.delete_stakeholder(stakeholder)

      query = "SELECT rolname FROM pg_roles WHERE rolname = $1"
      assert {:ok, %{num_rows: 0}} = Repo.query(query, [stakeholder.name])
    end

    test "delete_stakeholder/1 deletes the ddl schema", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)
      name = stakeholder.name

      assert {:ok, %{ddl_schema: nil}} = Stakeholders.delete_stakeholder(stakeholder)

      query = "SELECT schema_name FROM information_schema.schemata where schema_name = $1"
      assert {:ok, %{num_rows: 0}} = Repo.query(query, [name])
    end

    test "delete_stakeholder/1 iff the schema is empty", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)
      name = stakeholder.name

      query = "CREATE TABLE #{name}.delete_stakeholder_test_table ()"
      assert {:ok, _} = Repo.query(query)

      assert {:ok, %{ddl_schema: ^name}} = Stakeholders.delete_stakeholder(stakeholder)

      query = "SELECT schema_name FROM information_schema.schemata where schema_name = $1"
      assert {:ok, %{rows: [[^name]], num_rows: 1}} = Repo.query(query, [name])
    end

    test "change_stakeholder/1 returns a stakeholder changeset", %{user: user} do
      %{stakeholder: stakeholder} = stakeholder_fixture(user)
      assert %Ecto.Changeset{} = Stakeholders.change_stakeholder(stakeholder)
    end
  end
end
