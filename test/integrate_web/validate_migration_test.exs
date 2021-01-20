defmodule IntegrateWeb.ValidateMigrationTest do
  use IntegrateWeb.ConnCase

  alias Integrate.Repo

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "integratedb_unmet_claims()" do
    setup [:create_user, :authenticate, :create_stakeholder]

    test "returns no results when claims are fulfilled", %{conn: conn, stakeholder: stakeholder} do
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

      assert {:ok, %{rows: [], num_rows: 0}} =
               Repo.query("SELECT * from integratedb_unmet_claims()")
    end

    test "returns unmet claims when not fulfilled", %{conn: conn, stakeholder: stakeholder} do
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

      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos DROP COLUMN name")

      assert {:ok, %{rows: [row], num_rows: 1}} =
               Repo.query("SELECT * from integratedb_unmet_claims()")

      assert ["integratedb", "foos", "name", "character varying", 255, true] = row
    end
  end

  describe "integratedb_validate_migration()" do
    setup [:create_user, :authenticate, :create_stakeholder]

    test "runs successfully when valid", %{conn: conn, stakeholder: stakeholder} do
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

      assert {:ok, %{rows: [[0]], num_rows: 1}} =
               Repo.query("SELECT integratedb_validate_migration()")
    end

    test "raises exception when invalid", %{conn: conn, stakeholder: stakeholder} do
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

      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos DROP COLUMN name")

      assert {:error, %Postgrex.Error{postgres: err}} =
               Repo.query("SELECT integratedb_validate_migration()")

      assert %{code: :raise_exception, hint: "Please resolve the unmet claims above." <> _} = err
    end
  end

  describe "handles path alternatives" do
    setup [:create_user, :authenticate, :create_stakeholder]

    test "raises exception when invalid", %{conn: conn, stakeholder: stakeholder} do
      path = Routes.specification_path(conn, :update, stakeholder, :claims)

      {:ok, _} = Repo.query("CREATE TABLE integratedb.bars (name varchar(255));")

      payload = %{
        data: %{
          match: [
            %{
              path: ["integratedb.foos", "integratedb.bars"],
              fields: ["name"]
            }
          ]
        }
      }

      _resp =
        conn
        |> put(path, payload)
        |> json_response(200)

      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos DROP COLUMN name")

      assert {:ok, %{rows: [[0]], num_rows: 1}} =
               Repo.query("SELECT integratedb_validate_migration()")
    end
  end
end
