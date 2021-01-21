defmodule Integrate.SpecificationDataTest do
  @moduledoc """
  Test validating, expanding and contracting specification data.
  """
  use ExUnit.Case, async: true

  alias Ecto.Changeset

  alias Integrate.Util
  alias Integrate.Specification.Spec
  alias Integrate.SpecificationData, as: SpecData

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
      assert [{_, "#/match/0"}] = messages
    end

    test "path must be a string" do
      valid_data = %{
        match: [
          %{
            path: "foo.bar"
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
            path: ["array.of", "str.ings"]
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
        "foo.bar$"
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

    test "path table name can be an asterisk iff fields is too" do
      data = %{
        match: [
          %{
            path: "public.*",
            fields: ["*"]
          }
        ]
      }

      assert :ok = validate(data)

      data = %{
        match: [
          %{
            path: "public.*",
            fields: ["id"]
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

    test "fields can be an array containing a single asterisk" do
      data = %{
        match: [
          %{
            path: "public.foo",
            fields: ["*"]
          }
        ]
      }

      assert :ok = validate(data)

      data = %{
        match: [
          %{
            path: "public.foo",
            fields: "*"
          }
        ]
      }

      assert {:error, [{_, "#/match/0"}]} = validate(data)
    end

    test "asterisk must be the only field" do
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

    test "field alternatives can be strings" do
      data = %{
        match: [
          %{
            path: "public.foo",
            fields: [
              %{
                alternatives: [
                  "foo",
                  "bar"
                ]
              }
            ]
          }
        ]
      }

      assert :ok = validate(data)
    end

    test "match objects can have alternatives" do
      data = %{
        match: [
          %{
            alternatives: [
              %{
                path: "public.foo",
                fields: ["*"]
              },
              %{
                path: "public.alt_foo",
                fields: ["*"]
              }
            ]
          }
        ]
      }

      assert :ok = validate(data)
    end

    test "match objects can be optional" do
      data = %{
        match: [
          %{
            path: "public.foo",
            fields: ["*"],
            optional: true
          },
          %{
            alternatives: [
              %{
                path: "public.foo",
                fields: ["*"]
              }
            ],
            optional: true
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

      assert %{"match" => [%{"alternatives" => [%{"path" => path}]}]} = expand(data)
      assert %{"schema" => "public", "table" => "foo"} = path
    end

    test "path asterisk" do
      data = %{
        match: [
          %{path: "public.*"}
        ]
      }

      assert %{"match" => [%{"alternatives" => [%{"path" => path}]}]} = expand(data)
      assert %{"schema" => "public", "table" => "*"} = path
    end

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

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => []} = match_alt
    end

    test "fields nil" do
      data = build_data(fields: nil)

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => []} = match_alt
    end

    test "fields empty list" do
      data = build_data(fields: [])

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => []} = match_alt
    end

    test "fields asterisk" do
      data = build_data(fields: ["*"])

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => [a]} = match_alt
      assert %{"alternatives" => [%{"name" => "*"}]} = a
    end

    test "fields field names list" do
      data = build_data(fields: ["id"])

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => [a]} = match_alt
      assert %{"alternatives" => [%{"name" => "id"}]} = a

      data = build_data(fields: ["id", "uuid"])

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => [a, b]} = match_alt
      assert %{"alternatives" => [%{"name" => "id"}]} = a
      assert %{"alternatives" => [%{"name" => "uuid"}]} = b
    end

    test "fields field maps list" do
      data = build_data(fields: [%{"name" => "id"}])

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => [field_alt]} = match_alt
      assert %{"alternatives" => [%{"name" => "id"}]} = field_alt

      data = build_data(fields: [%{"name" => "id"}, %{"name" => "uuid"}])

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => [a, b]} = match_alt
      assert %{"alternatives" => [%{"name" => "id"}]} = a
      assert %{"alternatives" => [%{"name" => "uuid"}]} = b
    end

    test "fields map with type spec" do
      data = build_data(fields: [%{name: "bar", type: "varchar", min_length: 24}])

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => [%{"alternatives" => [field_alt]}]} = match_alt
      assert %{"name" => "bar", "type" => "varchar", "min_length" => 24} = field_alt
    end

    test "fields map with optional true" do
      data = build_data(fields: [%{name: "bar", optional: true}])

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => [%{"alternatives" => [field_alt], "optional" => optional}]} = match_alt
      assert %{"name" => "bar"} = field_alt
      assert true = optional
    end

    test "fields map with alternatives" do
      data = build_data(fields: [%{alternatives: [%{name: "foo"}, %{name: "bar"}]}])

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => [%{"alternatives" => field_alts}]} = match_alt
      assert [%{"name" => "foo"}, %{"name" => "bar"}] = field_alts
    end

    test "fields map with optional alternatives" do
      data = build_data(fields: [%{alternatives: [%{name: "foo"}], optional: true}])

      assert %{"match" => [%{"alternatives" => [match_alt]}]} = expand(data)
      assert %{"fields" => [%{"alternatives" => [field_alt], "optional" => optional}]} = match_alt
      assert %{"name" => "foo"} = field_alt
      assert true = optional
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
            alternatives: [
              %{
                path: %{
                  schema: "public",
                  table: "foo"
                }
              }
            ]
          }
        ]
      }

      assert %{match: [%{path: path}]} = contract(data)
      assert "public.foo" = path
    end

    test "path asterisk" do
      data = %{
        match: [
          %{
            alternatives: [
              %{
                path: %{
                  schema: "public",
                  table: "*"
                }
              }
            ]
          }
        ]
      }

      assert %{match: [%{path: path}]} = contract(data)
      assert "public.*" = path
    end

    test "path alternatives" do
      data = %{
        match: [
          %{
            alternatives: [
              %{
                path: %{
                  schema: "public",
                  table: "foo"
                }
              },
              %{
                path: %{
                  schema: "public",
                  table: "bar"
                }
              }
            ]
          }
        ]
      }

      %{match: [%{alternatives: [%{path: a}, %{path: b}]}]} = contract(data)
      assert ["public.foo", "public.bar"] = [a, b]
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
            alternatives: [
              %{
                path: %{
                  schema: "public",
                  table: "foo"
                },
                fields: fields
              }
            ]
          }
        ]
      }
    end

    test "fields empty list" do
      data = build_expanded_data(fields: [])

      assert %{match: [%{fields: []}]} = contract(data)
    end

    test "fields asterisk" do
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
