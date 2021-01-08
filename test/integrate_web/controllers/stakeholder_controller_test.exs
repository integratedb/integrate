defmodule IntegrateWeb.StakeholderControllerTest do
  use IntegrateWeb.ConnCase

  alias Integrate.Stakeholders.Stakeholder

  @create_attrs %{
    name: "some_name"
  }
  @update_attrs %{
    name: "some_updated_name"
  }
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:create_user, :authenticate]

    test "requires auth", %{unauthenticated_conn: conn} do
      conn
      |> post(Routes.stakeholder_path(conn, :index))
      |> assert_requires_auth()
    end

    test "lists all stakeholders", %{conn: conn} do
      conn = get(conn, Routes.stakeholder_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create stakeholder" do
    setup [:create_user, :authenticate]

    test "requires auth", %{unauthenticated_conn: conn, user: user} do
      attrs = Map.put(@create_attrs, :user_id, user.id)

      conn
      |> post(Routes.stakeholder_path(conn, :create), stakeholder: attrs)
      |> assert_requires_auth()
    end

    test "renders stakeholder when data is valid", %{conn: conn, user: user} do
      attrs = Map.put(@create_attrs, :user_id, user.id)

      conn = post(conn, Routes.stakeholder_path(conn, :create), stakeholder: attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.stakeholder_path(conn, :show, id))
      resp = json_response(conn, 200)["data"]

      assert resp == %{"id" => id, "name" => "some_name"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.stakeholder_path(conn, :create), stakeholder: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update stakeholder" do
    setup [:create_user, :authenticate, :create_stakeholder]

    test "requires auth", %{unauthenticated_conn: conn, stakeholder: stakeholder} do
      conn
      |> put(Routes.stakeholder_path(conn, :update, stakeholder), stakeholder: @update_attrs)
      |> assert_requires_auth()
    end

    test "renders stakeholder when data is valid", %{
      conn: conn,
      stakeholder: %Stakeholder{id: id} = stakeholder
    } do
      conn =
        put(conn, Routes.stakeholder_path(conn, :update, stakeholder), stakeholder: @update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.stakeholder_path(conn, :show, id))
      resp = json_response(conn, 200)["data"]

      assert resp == %{"id" => id, "name" => "some_updated_name"}
    end

    test "renders errors when data is invalid", %{conn: conn, stakeholder: stakeholder} do
      conn =
        put(conn, Routes.stakeholder_path(conn, :update, stakeholder), stakeholder: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete stakeholder" do
    setup [:create_user, :authenticate, :create_stakeholder]

    test "requires auth", %{unauthenticated_conn: conn, stakeholder: stakeholder} do
      conn
      |> delete(Routes.stakeholder_path(conn, :delete, stakeholder))
      |> assert_requires_auth()
    end

    test "deletes chosen stakeholder", %{conn: conn, stakeholder: stakeholder} do
      conn = delete(conn, Routes.stakeholder_path(conn, :delete, stakeholder))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.stakeholder_path(conn, :show, stakeholder))
      end
    end
  end
end
