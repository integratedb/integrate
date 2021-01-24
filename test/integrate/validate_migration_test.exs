defmodule Integrate.ValidateMigrationTest do
  use Integrate.DataCase

  alias Integrate.Repo
  alias Integrate.Specification
  alias Integrate.SpecificationData
  alias Integrate.Util

  defp set_spec(stakeholder, data) do
    {:ok, attrs} =
      data
      |> Util.to_string_keys()
      |> SpecificationData.validate_and_expand()

    Specification.set_spec(stakeholder, :claims, attrs)
  end

  describe "integratedb_unmet_claims()" do
    setup [:create_user, :create_stakeholder]

    test "returns no results when claims are fulfilled", %{stakeholder: stakeholder} do
      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: ["name", "inserted_at"]
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      assert {:ok, %{rows: [], num_rows: 0}} =
               Repo.query("SELECT * from integratedb_unmet_claims()")
    end

    test "returns unmet claims when not fulfilled", %{stakeholder: stakeholder} do
      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: ["name", "inserted_at"]
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos DROP COLUMN name")

      assert {:ok, %{rows: [[claim_id]], num_rows: 1}} =
               Repo.query("SELECT * from integratedb_unmet_claims()")

      assert is_integer(claim_id)
    end
  end

  describe "integratedb_validate_migration()" do
    setup [:create_user, :create_stakeholder]

    test "runs successfully when valid", %{stakeholder: stakeholder} do
      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: ["name", "inserted_at"]
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      assert {:ok, %{rows: [[0]], num_rows: 1}} =
               Repo.query("SELECT integratedb_validate_migration()")
    end

    test "raises exception when invalid", %{stakeholder: stakeholder} do
      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: ["name", "inserted_at"]
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos DROP COLUMN name")

      assert {:error, %Postgrex.Error{postgres: err}} =
               Repo.query("SELECT integratedb_validate_migration()")

      assert %{code: :raise_exception, hint: "Please resolve the unmet claims above." <> _} = err
    end
  end

  describe "handles match alternatives" do
    setup [:create_user, :create_stakeholder]

    test "supports missing tables", %{stakeholder: stakeholder} do
      {:ok, _} = Repo.query("CREATE TABLE integratedb.bars (name varchar(255));")

      data = %{
        match: [
          %{
            alternatives: [
              %{
                path: "integratedb.foos",
                fields: ["name", "inserted_at"]
              },
              %{
                path: "integratedb.bars",
                fields: ["name"]
              }
            ]
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      {:ok, _} = Repo.query("DROP TABLE integratedb.foos")

      assert {:ok, %{num_rows: 0}} = Repo.query("SELECT integratedb_unmet_claims()")
    end

    test "supports mismatching tables", %{stakeholder: stakeholder} do
      {:ok, _} = Repo.query("CREATE TABLE integratedb.bars (name varchar(255));")

      data = %{
        match: [
          %{
            alternatives: [
              %{
                path: "integratedb.foos",
                fields: ["name", "inserted_at"]
              },
              %{
                path: "integratedb.bars",
                fields: ["name"]
              }
            ]
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      {:ok, _} = Repo.query("ALTER TABLE integratedb.bars DROP COLUMN name")

      assert {:ok, %{num_rows: 0}} = Repo.query("SELECT integratedb_unmet_claims()")
    end

    test "unmet if no tables exist", %{stakeholder: stakeholder} do
      {:ok, _} = Repo.query("CREATE TABLE integratedb.bars (name varchar(255));")

      data = %{
        match: [
          %{
            alternatives: [
              %{
                path: "integratedb.foos",
                fields: ["name", "inserted_at"]
              },
              %{
                path: "integratedb.bars",
                fields: ["name"]
              }
            ]
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      {:ok, _} = Repo.query("DROP TABLE integratedb.foos")
      {:ok, _} = Repo.query("DROP TABLE integratedb.bars")

      assert {:ok, %{num_rows: 1}} = Repo.query("SELECT integratedb_unmet_claims()")
    end

    test "unmet if no tables match", %{stakeholder: stakeholder} do
      {:ok, _} = Repo.query("CREATE TABLE integratedb.bars (name varchar(255));")

      data = %{
        match: [
          %{
            alternatives: [
              %{
                path: "integratedb.foos",
                fields: ["name", "inserted_at"]
              },
              %{
                path: "integratedb.bars",
                fields: ["name"]
              }
            ]
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos DROP COLUMN name")
      {:ok, _} = Repo.query("ALTER TABLE integratedb.bars DROP COLUMN name")

      assert {:ok, %{num_rows: 1}} = Repo.query("SELECT integratedb_unmet_claims()")
    end

    test "supports optional tables", %{stakeholder: stakeholder} do
      {:ok, _} = Repo.query("CREATE TABLE integratedb.bars (name varchar(255));")

      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: ["name"],
            optional: true
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      {:ok, _} = Repo.query("DROP TABLE integratedb.foos")

      assert {:ok, %{num_rows: 0}} = Repo.query("SELECT integratedb_unmet_claims()")
    end
  end

  describe "handles field alternatives" do
    setup [:create_user, :create_stakeholder]

    test "supports empty fields", %{stakeholder: stakeholder} do
      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: []
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      assert {:ok, %{num_rows: 0}} = Repo.query("SELECT integratedb_unmet_claims()")
    end

    test "unmet if table removed even if fields empty", %{stakeholder: stakeholder} do
      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: []
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      {:ok, _} = Repo.query("DROP TABLE integratedb.foos")

      assert {:ok, %{num_rows: 1}} = Repo.query("SELECT integratedb_unmet_claims()")
    end

    test "supports missing fields", %{stakeholder: stakeholder} do
      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: [
              %{
                alternatives: [
                  "name",
                  "inserted_at"
                ]
              }
            ]
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos DROP COLUMN name")

      assert {:ok, %{num_rows: 0}} = Repo.query("SELECT integratedb_unmet_claims()")
    end

    test "unmet if no fields match", %{stakeholder: stakeholder} do
      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: [
              %{
                alternatives: [
                  "name",
                  "inserted_at"
                ]
              }
            ]
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos DROP COLUMN name")
      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos DROP COLUMN inserted_at")

      assert {:ok, %{num_rows: 1}} = Repo.query("SELECT integratedb_unmet_claims()")
    end

    test "supports optional fields", %{stakeholder: stakeholder} do
      data = %{
        match: [
          %{
            path: "integratedb.foos",
            fields: [
              %{
                name: "name",
                optional: true
              }
            ]
          }
        ]
      }

      {:ok, _} = set_spec(stakeholder, data)

      {:ok, _} = Repo.query("ALTER TABLE integratedb.foos DROP COLUMN name")

      assert {:ok, %{num_rows: 0}} = Repo.query("SELECT integratedb_unmet_claims()")
    end
  end
end
