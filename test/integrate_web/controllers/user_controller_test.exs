defmodule IntegrateWeb.UserControllerTest do
  use IntegrateWeb.ConnCase

  alias Integrate.Accounts
  alias Integrate.Accounts.User

  @create_attrs %{
    username: "some_name",
    password: "some password"
  }
  @update_attrs %{
    username: "some_updated_name",
    password: "some updated password"
  }
  @invalid_attrs %{username: nil, password: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:create_user, :authenticate]

    test "requires auth", %{unauthenticated_conn: conn} do
      conn
      |> post(Routes.user_path(conn, :index))
      |> assert_requires_auth()
    end

    test "lists all users", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :index))
      users = json_response(conn, 200)["data"]
      user_ids = Enum.map(users, fn x -> x["id"] end)
      assert user_ids == [user.id]
    end
  end

  describe "create user" do
    setup [:create_user, :authenticate]

    test "requires auth", %{unauthenticated_conn: conn} do
      conn
      |> post(Routes.user_path(conn, :create), user: @create_attrs)
      |> assert_requires_auth()
    end

    test "unless creating the root user", %{unauthenticated_conn: conn, user: user} do
      {:ok, _} = Accounts.delete_user(user)
      assert Accounts.list_users() == []

      # Works now without auth for the first user being created.
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert %{"id" => _id} = json_response(conn, 201)["data"]

      # Now requires auth for any subsequent calls.
      conn
      |> post(Routes.user_path(conn, :create), user: @update_attrs)
      |> assert_requires_auth()
    end

    test "returns id and credentials", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)

      assert %{
               "id" => _,
               "token" => _,
               "refreshToken" => _
             } = json_response(conn, 201)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user, :authenticate]

    test "requires auth", %{unauthenticated_conn: conn, user: user} do
      conn
      |> put(Routes.user_path(conn, :update, user), user: @update_attrs)
      |> assert_requires_auth()
    end

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))
      assert %{"id" => _, "username" => "some_updated_name"} = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user, :authenticate]

    test "requires auth", %{unauthenticated_conn: conn, user: user} do
      conn
      |> delete(Routes.user_path(conn, :delete, user))
      |> assert_requires_auth()
    end

    test "deletes chosen user", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      %{"id" => user_id} = json_response(conn, 201)["data"]

      conn = delete(conn, Routes.user_path(conn, :delete, user_id))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user_id))
      end
    end
  end
end
