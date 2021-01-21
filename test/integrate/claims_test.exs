defmodule Integrate.ClaimsTest do
  use Integrate.DataCase

  alias Integrate.Claims

  describe "claims" do
    setup [:create_user, :create_stakeholder, :create_spec]

    alias Integrate.Claims.Claim

    def claim_fixture(spec, attrs \\ %{}) do
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
      assert {:ok, %Claim{} = claim} = Claims.create_claim(spec, %{})
      assert claim.spec_id == spec.id
    end

    test "update_claim/2 with valid data updates the claim", %{spec: spec} do
      claim = claim_fixture(spec)
      assert {:ok, %Claim{}} = Claims.update_claim(claim, %{})
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

  describe "claim_alternatives" do
    setup [:create_user, :create_stakeholder, :create_spec, :create_claim]

    alias Integrate.Claims.ClaimAlternative

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

    def claim_alternative_fixture(claim, attrs \\ %{}) do
      attrs =
        attrs
        |> Enum.into(@valid_attrs)

      {:ok, claim_alternative} = Claims.create_claim_alternative(claim, attrs)

      claim_alternative
    end

    test "list_claim_alternatives/0 returns all claims", %{claim: claim} do
      claim_alternative = claim_alternative_fixture(claim)
      assert Claims.list_claim_alternatives() == [claim_alternative]
    end

    test "get_claim_alternative!/1 returns the claim_alternative with given id", %{claim: claim} do
      claim_alternative = claim_alternative_fixture(claim)
      assert Claims.get_claim_alternative!(claim_alternative.id) == claim_alternative
    end

    test "create_claim_alternative/1 with valid data creates a claim_alternative", %{claim: claim} do
      assert {:ok, %ClaimAlternative{} = claim_alternative} =
               Claims.create_claim_alternative(claim, @valid_attrs)

      assert claim_alternative.schema == "public"
      assert claim_alternative.table == "foo"
    end

    test "create_claim_alternative/1 with invalid data returns error changeset", %{claim: claim} do
      assert {:error, %Ecto.Changeset{}} = Claims.create_claim_alternative(claim, @invalid_attrs)
    end

    test "update_claim_alternative/2 with valid data updates the claim_alternative", %{
      claim: claim
    } do
      claim_alternative = claim_alternative_fixture(claim)

      assert {:ok, %ClaimAlternative{} = claim_alternative} =
               Claims.update_claim_alternative(claim_alternative, @update_attrs)

      assert claim_alternative.schema == "private"
      assert claim_alternative.table == "bar"
    end

    test "update_claim_alternative/2 with invalid data returns error changeset", %{claim: claim} do
      claim_alternative = claim_alternative_fixture(claim)

      assert {:error, %Ecto.Changeset{}} =
               Claims.update_claim_alternative(claim_alternative, @invalid_attrs)

      assert claim_alternative == Claims.get_claim_alternative!(claim_alternative.id)
    end

    test "delete_claim_alternative/1 deletes the claim_alternative", %{claim: claim} do
      claim_alternative = claim_alternative_fixture(claim)
      assert {:ok, %ClaimAlternative{}} = Claims.delete_claim_alternative(claim_alternative)

      assert_raise Ecto.NoResultsError, fn ->
        Claims.get_claim_alternative!(claim_alternative.id)
      end
    end

    test "change_claim_alternative/1 returns a claim_alternative changeset", %{claim: claim} do
      claim_alternative = claim_alternative_fixture(claim)
      assert %Ecto.Changeset{} = Claims.change_claim_alternative(claim_alternative)
    end
  end

  describe "columns" do
    setup [
      :create_user,
      :create_stakeholder,
      :create_spec,
      :create_claim,
      :create_claim_alternative
    ]

    alias Integrate.Claims.Column

    def column_fixture(claim_alternative, attrs \\ %{}) do
      {:ok, column} = Claims.create_column(claim_alternative, attrs)

      column
    end

    test "list_columns/0 returns all columns", %{claim_alternative: claim_alternative} do
      column = column_fixture(claim_alternative)
      assert Claims.list_columns() == [column]
    end

    test "get_column!/1 returns the column with given id", %{claim_alternative: claim_alternative} do
      column = column_fixture(claim_alternative)
      assert Claims.get_column!(column.id) == column
    end

    test "create_column/1 with valid data creates a column", %{
      claim_alternative: claim_alternative
    } do
      assert {:ok, %Column{} = column} = Claims.create_column(claim_alternative, %{})
      assert column.claim_alternative_id == claim_alternative.id
    end

    test "update_column/2 with valid data updates the column", %{
      claim_alternative: claim_alternative
    } do
      column = column_fixture(claim_alternative)
      assert {:ok, %Column{}} = Claims.update_column(column, %{})
    end

    test "delete_column/1 deletes the column", %{claim_alternative: claim_alternative} do
      column = column_fixture(claim_alternative)
      assert {:ok, %Column{}} = Claims.delete_column(column)
      assert_raise Ecto.NoResultsError, fn -> Claims.get_column!(column.id) end
    end

    test "change_column/1 returns a column changeset", %{claim_alternative: claim_alternative} do
      column = column_fixture(claim_alternative)
      assert %Ecto.Changeset{} = Claims.change_column(column)
    end
  end

  describe "column_alternatives" do
    setup [
      :create_user,
      :create_stakeholder,
      :create_spec,
      :create_claim,
      :create_claim_alternative,
      :create_column
    ]

    alias Integrate.Claims.ColumnAlternative

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

    def column_alternative_fixture(column, attrs \\ %{}) do
      attrs =
        attrs
        |> Enum.into(@valid_attrs)

      {:ok, column_alternative} = Claims.create_column_alternative(column, attrs)

      column_alternative
    end

    test "list_column_alternatives/0 returns all column_alternatives", %{column: column} do
      column_alternative = column_alternative_fixture(column)
      assert Claims.list_column_alternatives() == [column_alternative]
    end

    test "get_column_alternative!/1 returns the column_alternative with given id", %{
      column: column
    } do
      column_alternative = column_alternative_fixture(column)
      assert Claims.get_column_alternative!(column_alternative.id) == column_alternative
    end

    test "create_column_alternative/1 with valid data creates a column_alternative", %{
      column: column
    } do
      assert {:ok, %ColumnAlternative{} = column_alternative} =
               Claims.create_column_alternative(column, @valid_attrs)

      assert column_alternative.name == "id"
      assert column_alternative.type == "integer"
      assert column_alternative.is_nullable == true
      assert column_alternative.min_length == nil
    end

    test "create_column_alternative/1 with invalid data returns error changeset", %{
      column: column
    } do
      assert {:error, %Ecto.Changeset{}} =
               Claims.create_column_alternative(column, @invalid_attrs)
    end

    test "update_column_alternative/2 with valid data updates the column_alternative", %{
      column: column
    } do
      column_alternative = column_alternative_fixture(column)

      assert {:ok, %ColumnAlternative{} = column_alternative} =
               Claims.update_column_alternative(column_alternative, @update_attrs)

      assert column_alternative.name == "uuid"
      assert column_alternative.type == "varchar"
      assert column_alternative.is_nullable == false
      assert column_alternative.min_length == 40
    end

    test "update_column_alternative/2 with invalid data returns error changeset", %{
      column: column
    } do
      column_alternative = column_alternative_fixture(column)

      assert {:error, %Ecto.Changeset{}} =
               Claims.update_column_alternative(column_alternative, @invalid_attrs)

      assert column_alternative == Claims.get_column_alternative!(column_alternative.id)
    end

    test "delete_column_alternative/1 deletes the column_alternative", %{column: column} do
      column_alternative = column_alternative_fixture(column)
      assert {:ok, %ColumnAlternative{}} = Claims.delete_column_alternative(column_alternative)

      assert_raise Ecto.NoResultsError, fn ->
        Claims.get_column_alternative!(column_alternative.id)
      end
    end

    test "change_column_alternative/1 returns a column_alternative changeset", %{column: column} do
      column_alternative = column_alternative_fixture(column)
      assert %Ecto.Changeset{} = Claims.change_column_alternative(column_alternative)
    end
  end
end
