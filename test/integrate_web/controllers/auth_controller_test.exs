defmodule IntegrateWeb.AuthControllerTest do
  use IntegrateWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "login" do
    setup [:create_user]

    test "returns id and credentials", %{conn: conn, user: user, user_password: user_password} do
      attrs = %{
        username: user.username,
        password: user_password
      }

      path = Routes.auth_path(conn, :login)

      data =
        conn
        |> post(path, data: attrs)
        |> json_response(200)
        |> Map.get("data")

      assert %{"id" => _, "token" => _, "refreshToken" => _} = data
    end

    test "renders errors when data is invalid", %{conn: conn} do
      attrs = %{
        username: nil,
        password: nil
      }

      path = Routes.auth_path(conn, :login)

      errors =
        conn
        |> post(path, data: attrs)
        |> json_response(422)
        |> Map.get("errors")

      assert %{"password" => ["can't be blank"], "username" => ["can't be blank"]} = errors
    end

    test "renders errors when data is wrong", %{conn: conn, user: user} do
      attrs = %{
        username: user.username,
        password: "<wrong password>"
      }

      path = Routes.auth_path(conn, :login)

      errors =
        conn
        |> post(path, data: attrs)
        |> json_response(403)
        |> Map.get("errors")

      assert %{"detail" => "Forbidden"} = errors
    end
  end

  describe "renew" do
    setup [:create_user, :authenticate]

    test "returns id and credentials", %{conn: conn, refresh_token: refresh_token} do
      path = Routes.auth_path(conn, :renew)

      data =
        conn
        |> post(path, data: refresh_token)
        |> json_response(200)
        |> Map.get("data")

      assert %{"id" => _, "token" => _, "refreshToken" => _} = data
    end

    test "renders errors when data is wrong", %{conn: conn} do
      path = Routes.auth_path(conn, :renew)

      errors =
        conn
        |> post(path, data: nil)
        |> json_response(403)
        |> Map.get("errors")

      assert %{"detail" => "Forbidden"} = errors

      errors =
        conn
        |> post(path, data: "<wrong>")
        |> json_response(403)
        |> Map.get("errors")

      assert %{"detail" => "Forbidden"} = errors
    end
  end
end
