defmodule IntegrateWeb.SpecificationControllerTest do
  use IntegrateWeb.ConnCase

  alias Integrate.Specification

  alias Integrate.Specification.{
    Spec,
    Match,
    Field,
    Cell
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

    test "updates empty claims", %{conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :update, stakeholder, :claims)
      payload = %{data: @empty_matches}

      data =
        conn
        |> put(path, payload)
        |> json_response(200)
        |> Map.get("data")

      assert %{"type" => "CLAIMS", "match" => []} = data
    end

    test "updates claims", %{conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :update, stakeholder, :claims)

      payload = %{
        data: %{
          match: [
            %{
              path: "public.foo",
              fields: ["id", "uid", "guid"]
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
      assert %{"fields" => ["id", "uid", "guid"], "path" => "public.foo"} = match

      %Spec{match: [%Match{fields: [a, b, c]}]} = Specification.get_spec(stakeholder.id, :claims)
      assert %Field{alternatives: [%Cell{name: "id"}]} = a
      assert %Field{alternatives: [%Cell{name: "uid"}]} = b
      assert %Field{alternatives: [%Cell{name: "guid"}]} = c
    end
  end
end
