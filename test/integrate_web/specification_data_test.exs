defmodule IntegrateWeb.SpecificationDataTest do
  @moduledoc """
  // Spec
  data: {
    // embeds_many :matches, Match
    match: [
      {
        // embeds_one :path, Path
        path:
          // - parse these:
          "public.*", // only valid if fields is also ["*"]
          "public.orders",
          ["public.orders", "public.legacy_orders"]
          // - into this:
          {
            // an array of strings
            alternatives: [
              "public.orders",
              "public.legacy_orders"
            ]
          }

        // embeds_many :fields, Field
        fields: [
          // - parse these:
          "*",
          "user_id",
          {
            name: "*",
          },
          {
            name: "user_id",
          },
          {
            name: "user_id",
            optional: true
          },
          {
            alternatives: ["name", "firstname"]
          },
          // - into this:
          {
            // embeds_many :alternatives, Cell
            alternatives: [
              {
                name: "name",
                type: null,
                min_length: null
              },
              {
                name: "firstname",
                type: "varchar",
                min_length: 24
              }
            ],
            optional: true || false
          }
        ],

        // array of strings
        events: [],

        // array of strings
        channels: []
      }
  """
  use ExUnit.Case, async: true

  alias Ecto.Changeset

  alias Integrate.Util
  alias Integrate.Specification.Spec
  alias IntegrateWeb.SpecificationData, as: SpecData

  def validate(data) do
    data
    |> Util.to_string_keys()
    |> SpecData.validate()
  end

  describe "validate" do
    test "requires a top level `match` array" do
      assert {:error, [{_, "#"}]} = validate(%{})
    end

    test "top level `match` array can be empty" do
      data = %{
        match: []
      }

      assert :ok = validate(data)
    end

    test "match obj must have a `path`" do
      data = %{
        match: [
          %{}
        ]
      }

      {:error, messages} = validate(data)
      assert [_, {_, "#/match/0"}] = messages
    end

    test "path can be a string, or an array of strings" do
      valid_data = %{
        match: [
          %{
            path: "foo.bar"
          },
          %{
            path: ["foo.bar", "foo.baz"]
          }
        ]
      }

      assert :ok = validate(valid_data)

      invalid_data = %{
        match: [
          %{
            path: %{}
          },
          %{
            path: 22
          }
        ]
      }

      {:error, messages} = validate(invalid_data)
      assert [{_, "#/match/0"}, {_, "#/match/1"}] = messages
    end

    test "path items must be in \"schema.table\" format" do
      invalid_paths = [
        nil,
        "foo",
        "foo.",
        "foo.22",
        ".foo",
        "'; drop lil bobby tables;",
        "foo.bar$",
        ["foo"],
        ["foo", "foo.bar"],
        ["foo.22", "foo.bar"],
        ["'; drop lil bobby tables;", "foo.bar"]
      ]

      invalid_paths
      |> Enum.each(fn path ->
        invalid_data = %{
          match: [
            %{
              path: path,
              fields: []
            }
          ]
        }

        case validate(invalid_data) do
          {:error, messages} ->
            assert [{_, "#/match/0"}] = messages

          :ok ->
            IO.inspect({
              "Invalid path didn't error.",
              invalid_data
            })

            assert false
        end
      end)
    end

    test "path table name can be an asterix" do
      data = %{
        match: [
          %{
            path: "public.*",
            fields: "*"
          }
        ]
      }

      assert :ok = validate(data)

      data = %{
        match: [
          %{
            path: "public.*",
            fields: ["*"]
          }
        ]
      }

      assert :ok = validate(data)
    end

    test "iff single path given" do
      data = %{
        match: [
          %{
            path: ["public.*"],
            fields: ["*"]
          }
        ]
      }

      assert :ok = validate(data)

      data = %{
        match: [
          %{
            path: ["public.*", "foo.bar"],
            fields: "*"
          }
        ]
      }

      assert {:error, [{_, "#/match/0"}]} = validate(data)
    end

    test "and iff fields is also an asterix" do
      data = %{
        match: [
          %{
            path: "public.*",
            fields: ["id", "uuid"]
          }
        ]
      }

      assert {:error, [{_, "#/match/0"}]} = validate(data)
    end

    test "fields can be an empty list" do
      data = %{
        match: [
          %{
            path: "public.foo",
            fields: []
          }
        ]
      }

      assert :ok = validate(data)
    end

    test "fields can be asterix" do
      data = %{
        match: [
          %{
            path: "public.foo",
            fields: "*"
          }
        ]
      }

      assert :ok = validate(data)

      data = %{
        match: [
          %{
            path: "public.foo",
            fields: ["*"]
          }
        ]
      }

      assert :ok = validate(data)
    end

    test "asterix must be the only field" do
      data = %{
        match: [
          %{
            path: "public.foo",
            fields: ["name", "*"]
          }
        ]
      }

      assert {:error, [{_, "#/match/0"}]} = validate(data)
    end

    test "fields cannot be a single column name" do
      data = %{
        match: [
          %{
            path: "public.foo",
            fields: "uuid"
          }
        ]
      }

      assert {:error, [{_, "#/match/0"}]} = validate(data)
    end

    test "fields can be an array of column names" do
      data = %{
        match: [
          %{
            path: "public.foo",
            fields: ["id"]
          },
          %{
            path: "public.bar",
            fields: ["id", "uuid"]
          }
        ]
      }

      assert :ok = validate(data)
    end

    test "fields string must be a valid name" do
      invalid_names = [
        ".foo",
        "'; drop lil bobby tables;",
        "foo.bar$"
      ]

      invalid_names
      |> Enum.each(fn name ->
        invalid_data = %{
          match: [
            %{
              path: "public.foo",
              fields: [name]
            }
          ]
        }

        case validate(invalid_data) do
          {:error, messages} ->
            assert [{_, "#/match/0"}] = messages

          :ok ->
            IO.inspect({
              "Invalid name didn't error.",
              invalid_data
            })

            assert false
        end
      end)
    end

    test "fields can be an object with a name" do
      data = %{
        match: [
          %{
            path: "public.foo",
            fields: [
              %{
                name: "bar"
              }
            ]
          }
        ]
      }

      assert :ok = validate(data)
    end

    test "field objects can have type, min_length and optional" do
      data = %{
        match: [
          %{
            path: "public.foo",
            fields: [
              %{
                name: "bar",
                type: "varchar",
                min_length: 24
              },
              %{
                name: "baz",
                optional: true
              }
            ]
          }
        ]
      }

      assert :ok = validate(data)
    end

    test "field objects can have alternatives" do
      data = %{
        match: [
          %{
            path: "public.foo",
            fields: [
              %{
                alternatives: [
                  %{name: "foo"},
                  %{name: "bar"}
                ]
              },
              %{
                alternatives: [
                  %{name: "baz"}
                ],
                optional: true
              }
            ]
          }
        ]
      }

      assert :ok = validate(data)
    end
  end

  def expand(data) do
    data
    |> Util.to_string_keys()
    |> SpecData.expand()
  end

  describe "expand" do
    test "path" do
      data = %{
        match: [
          %{path: "public.foo"}
        ]
      }

      %{"match" => [%{"path" => path}]} = expand(data)
      assert %{"alternatives" => ["public.foo"]} = path
    end

    test "path array" do
      data = %{
        match: [
          %{path: ["public.foo"]}
        ]
      }

      %{"match" => [%{"path" => path}]} = expand(data)
      assert %{"alternatives" => ["public.foo"]} = path

      data = %{
        match: [
          %{path: ["public.foo", "public.bar"]}
        ]
      }

      %{"match" => [%{"path" => path}]} = expand(data)
      assert %{"alternatives" => ["public.foo", "public.bar"]} = path
    end

    test "path asterix" do
      data = %{
        match: [
          %{path: "public.*"}
        ]
      }

      %{"match" => [%{"path" => path}]} = expand(data)
      assert %{"alternatives" => ["public.*"]} = path
    end

    # fields: "*"
    # fields: ["*"]
    # fields: []
    # fields: ["id"]
    # fields: ["id", "uuid"]
    # fields: [%{name: "bar"}]
    # fields: [
    #   %{name: "bar", type: "varchar", min_length: 24},
    #   %{name: "baz", optional: true}
    # ]
    # fields: [
    #   %{alternatives: [%{name: "foo"}, %{name: "bar"}]},
    #   %{alternatives: [%{name: "baz"}], optional: true}
    # ]

    defp build_data(fields: fields) do
      %{
        match: [
          %{
            path: "public.foo",
            fields: fields
          }
        ]
      }
    end

    test "fields missing" do
      data = %{match: [%{path: "public.foo"}]}

      assert %{"match" => [%{"fields" => []}]} = expand(data)
    end

    test "fields nil" do
      data = build_data(fields: nil)

      assert %{"match" => [%{"fields" => []}]} = expand(data)
    end

    test "fields empty list" do
      data = build_data(fields: [])

      assert %{"match" => [%{"fields" => []}]} = expand(data)
    end

    test "fields asterix" do
      data = build_data(fields: "*")

      %{"match" => [%{"fields" => [field]}]} = expand(data)
      assert %{"alternatives" => [%{"name" => "*"}], "optional" => false} = field
    end

    test "fields single asterix in list" do
      data = build_data(fields: ["*"])

      %{"match" => [%{"fields" => [field]}]} = expand(data)
      assert %{"alternatives" => [%{"name" => "*"}], "optional" => false} = field
    end

    test "fields field names list" do
      data = build_data(fields: ["id"])

      %{"match" => [%{"fields" => [field]}]} = expand(data)
      assert %{"alternatives" => [%{"name" => "id"}], "optional" => false} = field

      data = build_data(fields: ["id", "uuid"])

      %{"match" => [%{"fields" => [a, b]}]} = expand(data)
      assert %{"alternatives" => [%{"name" => "id"}], "optional" => false} = a
      assert %{"alternatives" => [%{"name" => "uuid"}], "optional" => false} = b
    end

    test "fields field maps list" do
      data = build_data(fields: [%{"name" => "id"}])

      %{"match" => [%{"fields" => [field]}]} = expand(data)
      assert %{"alternatives" => [%{"name" => "id"}], "optional" => false} = field

      data = build_data(fields: [%{"name" => "id"}, %{"name" => "uuid"}])

      %{"match" => [%{"fields" => [a, b]}]} = expand(data)
      assert %{"alternatives" => [%{"name" => "id"}], "optional" => false} = a
      assert %{"alternatives" => [%{"name" => "uuid"}], "optional" => false} = b
    end

    test "fields map with type spec" do
      data = build_data(fields: [%{name: "bar", type: "varchar", min_length: 24}])

      %{"match" => [%{"fields" => [field]}]} = expand(data)
      %{"alternatives" => [cell], "optional" => false} = field
      assert %{"name" => "bar", "type" => "varchar", "min_length" => 24} = cell
    end

    test "fields map with optional true" do
      data = build_data(fields: [%{name: "bar", optional: true}])

      %{"match" => [%{"fields" => [field]}]} = expand(data)
      assert %{"alternatives" => [%{"name" => "bar"}], "optional" => true} = field
    end

    test "fields map with alternatives" do
      data = build_data(fields: [%{alternatives: [%{name: "foo"}, %{name: "bar"}]}])

      %{"match" => [%{"fields" => [field]}]} = expand(data)

      assert %{"alternatives" => [%{"name" => "foo"}, %{"name" => "bar"}], "optional" => false} =
               field
    end

    test "fields map with optional alternatives" do
      data = build_data(fields: [%{alternatives: [%{name: "foo"}], optional: true}])

      %{"match" => [%{"fields" => [field]}]} = expand(data)
      assert %{"alternatives" => [%{"name" => "foo"}], "optional" => true} = field
    end
  end

  def contract(data) do
    attrs =
      data
      |> Map.put(:stakeholder_id, 1234)
      |> Map.put(:type, Spec.types(:claims))

    spec =
      %Spec{}
      |> Spec.changeset(attrs)
      |> Changeset.apply_changes()

    spec
    |> SpecData.contract()
  end

  describe "contract" do
    test "path" do
      data = %{
        match: [
          %{
            path: %{
              alternatives: ["public.foo"]
            },
            fields: []
          }
        ]
      }

      %{match: [%{path: path}]} = contract(data)
      assert "public.foo" = path
    end

    test "path asterix" do
      data = %{
        match: [
          %{
            path: %{
              alternatives: ["public.*"]
            },
            fields: []
          }
        ]
      }

      %{match: [%{path: path}]} = contract(data)
      assert "public.*" = path
    end

    test "path alternatives" do
      data = %{
        match: [
          %{
            path: %{
              alternatives: ["public.foo", "public.bar"]
            },
            fields: []
          }
        ]
      }

      %{match: [%{path: path}]} = contract(data)
      assert ["public.foo", "public.bar"] = path
    end

    # fields: "*"
    # fields: ["*"]
    # fields: []
    # fields: ["id"]
    # fields: ["id", "uuid"]
    # fields: [%{name: "bar"}]
    # fields: [
    #   %{name: "bar", type: "varchar", min_length: 24},
    #   %{name: "baz", optional: true}
    # ]
    # fields: [
    #   %{alternatives: [%{name: "foo"}, %{name: "bar"}]},
    #   %{alternatives: [%{name: "baz"}], optional: true}
    # ]

    defp build_expanded_data(fields: fields) do
      %{
        match: [
          %{
            path: %{
              alternatives: ["public.foo"]
            },
            fields: fields
          }
        ]
      }
    end

    test "fields empty list" do
      data = build_expanded_data(fields: [])

      assert %{match: [%{fields: []}]} = contract(data)
    end

    test "fields asterix" do
      expanded_field = %{alternatives: [%{name: "*"}], optional: false}
      data = build_expanded_data(fields: [expanded_field])

      %{match: [%{fields: [field]}]} = contract(data)
      assert "*" = field
    end

    test "fields field names list" do
      expanded_field = %{alternatives: [%{name: "id"}], optional: false}
      data = build_expanded_data(fields: [expanded_field])

      %{match: [%{fields: [field]}]} = contract(data)
      assert "id" = field

      a = %{alternatives: [%{name: "id"}], optional: false}
      b = %{alternatives: [%{name: "uuid"}], optional: false}
      data = build_expanded_data(fields: [a, b])

      %{match: [%{fields: fields}]} = contract(data)
      assert ["id", "uuid"] = fields
    end

    test "fields map with type spec" do
      expanded_field = %{alternatives: [%{name: "id", type: "varchar"}], optional: false}
      data = build_expanded_data(fields: [expanded_field])

      %{match: [%{fields: [field]}]} = contract(data)
      assert %{name: "id", type: "varchar"} = field
    end

    test "fields map with optional true" do
      expanded_field = %{alternatives: [%{name: "id"}], optional: true}
      data = build_expanded_data(fields: [expanded_field])

      %{match: [%{fields: [field]}]} = contract(data)
      assert %{name: "id", optional: true} = field
    end

    test "fields map with alternatives" do
      expanded_field = %{alternatives: [%{name: "id"}, %{name: "uuid"}], optional: false}
      data = build_expanded_data(fields: [expanded_field])

      %{match: [%{fields: [field]}]} = contract(data)
      assert %{alternatives: [%{name: "id"}, %{name: "uuid"}]} = field
    end

    test "fields map with optional alternatives" do
      expanded_field = %{alternatives: [%{name: "id"}, %{name: "uuid"}], optional: true}
      data = build_expanded_data(fields: [expanded_field])

      %{match: [%{fields: [field]}]} = contract(data)
      assert %{alternatives: [%{name: "id"}, %{name: "uuid"}], optional: true} = field
    end
  end
end
