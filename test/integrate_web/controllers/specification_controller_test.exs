defmodule IntegrateWeb.SpecificationControllerTest do
  use IntegrateWeb.ConnCase

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

      assert data == %{"type" => "claims", "match" => []}
    end
  end

  describe "update claims" do
    setup [:create_user, :authenticate, :create_stakeholder]

    test "requires auth", %{unauthenticated_conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :update, stakeholder, :claims)
      payload = %{"data" => @empty_matches}

      conn
      |> put(path, payload)
      |> assert_requires_auth()
    end

    test "updates empty claims", %{conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :update, stakeholder, :claims)
      payload = %{"data" => @empty_matches}

      data =
        conn
        |> put(path, payload)
        |> json_response(200)
        |> Map.get("data")

      assert data == %{"type" => "claims", "match" => []}
    end
  end
end
