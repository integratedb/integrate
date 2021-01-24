defmodule IntegrateWeb.SpecificationControllerTest do
  use IntegrateWeb.ConnCase

  alias Integrate.Specification

  alias Integrate.Specification.{
    Spec,
    Match,
    MatchAlternative,
    Field,
    FieldAlternative
  }

  alias Integrate.Claims

  alias Integrate.Claims.{
    Claim,
    ClaimAlternative,
    Column,
    ColumnAlternative
  }

  @empty_matches %{
    match: []
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show claims" do
    setup [:create_user, :authenticate, :create_stakeholder]

    test "requires auth", %{unauthenticated_conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :show, stakeholder, :claims)

      conn
      |> get(path)
      |> assert_requires_auth()
    end

    test "shows claims", %{conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :show, stakeholder, :claims)

      data =
        conn
        |> get(path)
        |> json_response(200)
        |> Map.get("data")

      assert %{"type" => "CLAIMS", "match" => []} = data
    end
  end

  describe "update claims" do
    setup [:create_user, :authenticate, :create_stakeholder]

    test "requires auth", %{unauthenticated_conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :update, stakeholder, :claims)
      payload = %{data: @empty_matches}

      conn
      |> put(path, payload)
      |> assert_requires_auth()
    end

    test "with empty claims", %{conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :update, stakeholder, :claims)
      payload = %{data: @empty_matches}

      data =
        conn
        |> put(path, payload)
        |> json_response(200)
        |> Map.get("data")

      assert %{"type" => "CLAIMS", "match" => []} = data
      assert %Spec{match: []} = Specification.get_spec(stakeholder, :claims)
    end

    test "valid claims sets the spec", %{conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :update, stakeholder, :claims)

      payload = %{
        data: %{
          match: [
            %{
              path: "integratedb.foos",
              fields: ["name", "inserted_at"]
            }
          ]
        }
      }

      data =
        conn
        |> put(path, payload)
        |> json_response(200)
        |> Map.get("data")

      # This is the contracted data response.
      assert %{"type" => "CLAIMS", "match" => [match]} = data
      assert %{"fields" => ["name", "inserted_at"], "path" => "integratedb.foos"} = match

      # This is the expanded spec data we saved.
      assert %Spec{match: [match]} = Specification.get_spec(stakeholder, :claims)
      assert %Match{alternatives: [%MatchAlternative{fields: [a, b]}]} = match
      assert %Field{alternatives: [%FieldAlternative{name: "name"}]} = a
      assert %Field{alternatives: [%FieldAlternative{name: "inserted_at"}]} = b
    end

    test "valid claims also saves claims", %{conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :update, stakeholder, :claims)

      payload = %{
        data: %{
          match: [
            %{
              path: "integratedb.foos",
              fields: ["name", "inserted_at"]
            }
          ]
        }
      }

      _resp =
        conn
        |> put(path, payload)
        |> json_response(200)

      claims =
        stakeholder
        |> Specification.get_spec(:claims)
        |> Claims.get_by_spec()

      assert [%Claim{alternatives: [claim_alt]}] = claims
      assert %ClaimAlternative{schema: "integratedb", table: "foos", columns: [a, b]} = claim_alt
      assert %Column{alternatives: [%ColumnAlternative{name: "name"}]} = a
      assert %Column{alternatives: [%ColumnAlternative{name: "inserted_at"}]} = b
    end

    test "invalid claims returns column errors", %{conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :update, stakeholder, :claims)

      payload = %{
        data: %{
          match: [
            %{
              path: "integratedb.foos",
              fields: [
                %{
                  name: "name",
                  type: "int"
                },
                %{
                  name: "insortulated_at"
                }
              ]
            }
          ]
        }
      }

      errors =
        conn
        |> put(path, payload)
        |> json_response(422)
        |> Map.get("errors")

      assert %{"claims" => [%{"alternatives" => [claim_alts]}]} = errors
      assert %{"columns" => [%{"alternatives" => [a]}, %{"alternatives" => [b]}]} = claim_alts

      assert %{"type" => ["path: `integratedb.foos`, field: `name`: " <> m]} = a
      assert "specified value `int` does not match existing column value `character varying`." = m

      assert %{"name" => ["path: `integratedb.foos`, field: `insortulated_at`: " <> mb]} = b
      assert "specified field `insortulated_at` does not exist in the database." = mb
    end
  end
end
