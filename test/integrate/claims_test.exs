defmodule Integrate.ClaimsTest do
  use Integrate.DataCase

  alias Integrate.Claims

  describe "claims" do
    setup [:create_user, :create_stakeholder, :create_spec]

    alias Integrate.Claims.Claim

    @valid_attrs %{
      schema: "public",
      table: "foo"
    }

    @update_attrs %{
      schema: "private",
      table: "bar"
    }

    @invalid_attrs %{
      schema: "not.a.schema",
      table: "'; drop bobby tables;"
    }

    def claim_fixture(spec, attrs \\ %{}) do
      attrs =
        attrs
        |> Enum.into(@valid_attrs)

      {:ok, claim} = Claims.create_claim(spec, attrs)

      claim
    end

    test "list_claims/0 returns all claims", %{spec: spec} do
      claim = claim_fixture(spec)
      assert Claims.list_claims() == [claim]
    end

    test "get_claim!/1 returns the claim with given id", %{spec: spec} do
      claim = claim_fixture(spec)
      assert Claims.get_claim!(claim.id) == claim
    end

    test "create_claim/1 with valid data creates a claim", %{spec: spec} do
      assert {:ok, %Claim{} = claim} = Claims.create_claim(spec, @valid_attrs)
      assert claim.schema == "public"
      assert claim.table == "foo"
    end

    test "create_claim/1 with invalid data returns error changeset", %{spec: spec} do
      assert {:error, %Ecto.Changeset{}} = Claims.create_claim(spec, @invalid_attrs)
    end

    test "update_claim/2 with valid data updates the claim", %{spec: spec} do
      claim = claim_fixture(spec)
      assert {:ok, %Claim{} = claim} = Claims.update_claim(claim, @update_attrs)
      assert claim.schema == "private"
      assert claim.table == "bar"
    end

    test "update_claim/2 with invalid data returns error changeset", %{spec: spec} do
      claim = claim_fixture(spec)
      assert {:error, %Ecto.Changeset{}} = Claims.update_claim(claim, @invalid_attrs)
      assert claim == Claims.get_claim!(claim.id)
    end

    test "delete_claim/1 deletes the claim", %{spec: spec} do
      claim = claim_fixture(spec)
      assert {:ok, %Claim{}} = Claims.delete_claim(claim)
      assert_raise Ecto.NoResultsError, fn -> Claims.get_claim!(claim.id) end
    end

    test "change_claim/1 returns a claim changeset", %{spec: spec} do
      claim = claim_fixture(spec)
      assert %Ecto.Changeset{} = Claims.change_claim(claim)
    end
  end

  describe "columns" do
    setup [:create_user, :create_stakeholder, :create_spec, :create_claim]

    alias Integrate.Claims.Column

    @valid_attrs %{
      name: "id",
      type: "integer",
      is_nullable: true,
      min_length: nil
    }

    @update_attrs %{
      name: "uuid",
      type: "varchar",
      is_nullable: false,
      min_length: 40
    }

    @invalid_attrs %{
      name: nil,
      type: nil,
      is_nullable: nil
    }

    def column_fixture(claim, attrs \\ %{}) do
      attrs =
        attrs
        |> Enum.into(@valid_attrs)

      {:ok, column} = Claims.create_column(claim, attrs)

      column
    end

    test "list_columns/0 returns all columns", %{claim: claim} do
      column = column_fixture(claim)
      assert Claims.list_columns() == [column]
    end

    test "get_column!/1 returns the column with given id", %{claim: claim} do
      column = column_fixture(claim)
      assert Claims.get_column!(column.id) == column
    end

    test "create_column/1 with valid data creates a column", %{claim: claim} do
      assert {:ok, %Column{} = column} = Claims.create_column(claim, @valid_attrs)
      assert column.name == "id"
      assert column.type == "integer"
      assert column.is_nullable == true
      assert column.min_length == nil
    end

    test "create_column/1 with invalid data returns error changeset", %{claim: claim} do
      assert {:error, %Ecto.Changeset{}} = Claims.create_column(claim, @invalid_attrs)
    end

    test "update_column/2 with valid data updates the column", %{claim: claim} do
      column = column_fixture(claim)
      assert {:ok, %Column{} = column} = Claims.update_column(column, @update_attrs)
      assert column.name == "uuid"
      assert column.type == "varchar"
      assert column.is_nullable == false
      assert column.min_length == 40
    end

    test "update_column/2 with invalid data returns error changeset", %{claim: claim} do
      column = column_fixture(claim)
      assert {:error, %Ecto.Changeset{}} = Claims.update_column(column, @invalid_attrs)
      assert column == Claims.get_column!(column.id)
    end

    test "delete_column/1 deletes the column", %{claim: claim} do
      column = column_fixture(claim)
      assert {:ok, %Column{}} = Claims.delete_column(column)
      assert_raise Ecto.NoResultsError, fn -> Claims.get_column!(column.id) end
    end

    test "change_column/1 returns a column changeset", %{claim: claim} do
      column = column_fixture(claim)
      assert %Ecto.Changeset{} = Claims.change_column(column)
    end
  end
end
