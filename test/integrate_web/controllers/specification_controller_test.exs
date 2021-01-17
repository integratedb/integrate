defmodule IntegrateWeb.SpecificationControllerTest do
  use IntegrateWeb.ConnCase

  alias Integrate.Specification

  alias Integrate.Specification.{
    Spec,
    Match,
    Field,
    Cell
  }

  alias Integrate.Claims

  alias Integrate.Claims.{
    Claim,
    Column
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
      assert %Spec{match: []} = Specification.get_spec(stakeholder.id, :claims)
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

      %{"type" => "CLAIMS", "match" => [match]} = data
      assert %{"fields" => ["name", "inserted_at"], "path" => "integratedb.foos"} = match

      %Spec{match: [%Match{fields: [a, b]}]} = Specification.get_spec(stakeholder.id, :claims)
      assert %Field{alternatives: [%Cell{name: "name"}]} = a
      assert %Field{alternatives: [%Cell{name: "inserted_at"}]} = b
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
        stakeholder.id
        |> Specification.get_spec(:claims)
        |> Claims.get_by_spec()

      assert [%Claim{schema: "integratedb", table: "foos", columns: columns}] = claims
      assert [%Column{name: "name"}, %Column{name: "inserted_at"}] = columns
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

      assert %{"claims" => [%{"columns" => [a, b]}]} = errors

      assert %{"type" => ["path: `integratedb.foos`, field: `name`: " <> m]} = a
      assert "specified value `int` does not match existing column value `character varying`." = m

      assert %{"name" => ["path: `integratedb.foos`, field: `insortulated_at`: " <> mb]} = b
      assert "specified field `insortulated_at` does not exist in the database." = mb
    end
  end
end
