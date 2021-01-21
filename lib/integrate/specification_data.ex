defmodule Integrate.SpecificationData do
  @moduledoc """
  Validate and transform specification data.
  """
  use Memoize

  alias ExJsonSchema.{
    Schema,
    Validator
  }

  alias Integrate.Util

  alias Integrate.Specification.{
    Spec,
    Match,
    MatchAlternative,
    Path,
    Field,
    FieldAlternative
  }

  @doc """
  Use a JSON Schema to validate user input specifications.

  Returns `:ok` or `{:error, json_schema_errors}`.

  ## Examples

      iex> validate(%{})
      :ok

      iex> validate(%{"foo" => 1})
      {:error, [{"Type mismatch. Expected String but got Integer.", "#/foo"}]}

  """
  def validate(data) do
    "spec.schema.json"
    |> resolve_schema()
    |> Validator.validate(patch(data))
  end

  defmemo resolve_schema(name) do
    ["spec", name]
    |> Util.read_priv_file!()
    |> Jason.decode!()
    |> Schema.resolve()
  end

  # XXX Fix me.
  # Our `spec.schema.json` JSON schema currently fails to allow an empty fields array
  # like `fields: []`. This is a natural syntax for a user to write, so in lieu of better
  # schema foo, workaround for now by patching the input data.
  defp patch(%{"match" => matches} = data) when is_list(matches) do
    %{data | "match" => Enum.map(matches, &patch_fields/1)}
  end

  defp patch(data), do: data

  defp patch_fields(%{"alternatives" => alternatives} = match) do
    %{match | "alternatives" => Enum.map(alternatives, &patch_fields/1)}
  end

  defp patch_fields(%{"fields" => []} = match) do
    %{match | "fields" => nil}
  end

  defp patch_fields(match), do: match

  @doc """
  Expand "terse" syntactic sugar in the spec data into its equivalent full form.

  Accepts and returns a map.

  ## Examples


      iex> expand(%{"match": [%{path" => "public.users", "fields" => ["id", "uuid"]}]})
      %{
        "match" => [
          %{
            "alternatives" => [
              "path" => %{
                "schema" => "public",
                "table" => "users"
              },
              "fields" => [
                %{
                  "alternatives" => [
                    %{"name" => "id"}
                  ]
                },
                %{
                  "alternatives" => [
                    %{"name": "uuid"}
                  ]
                }
              }
            ]
          }
        ]
      }

  """
  def expand(%{"match" => matches} = data) do
    %{data | "match" => Enum.map(matches, &expand_match/1)}
  end

  defp expand_match(match) when not is_map_key(match, "alternatives") do
    {optional, match_alt} = Map.pop(match, "optional")

    match = %{
      "alternatives" => [match_alt]
    }

    match =
      case optional do
        nil ->
          match

        val ->
          Map.put(match, "optional", val)
      end

    match
    |> expand_match()
  end

  defp expand_match(%{"alternatives" => alternatives} = match) do
    %{match | "alternatives" => Enum.map(alternatives, &expand_match_alt/1)}
  end

  defp expand_match_alt(match_alt) when not is_map_key(match_alt, "fields") do
    match_alt
    |> Map.put_new("fields", [])
    |> expand_match_alt()
  end

  defp expand_match_alt(%{"fields" => nil} = match_alt) do
    %{match_alt | "fields" => []}
    |> expand_match_alt()
  end

  defp expand_match_alt(%{"path" => path, "fields" => fields} = match) do
    %{match | "path" => expand_path(path), "fields" => expand_fields(fields)}
  end

  # path: "public.*"
  # path: "public.foo"

  defp expand_path(path) when is_binary(path) do
    [schema, table] = String.split(path, ".")

    %{"schema" => schema, "table" => table}
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

  defp expand_fields(nil) do
    expand_fields([])
  end

  defp expand_fields("*") do
    expand_fields(["*"])
  end

  defp expand_fields(fields) when is_list(fields) do
    fields
    |> Enum.map(&expand_field/1)
  end

  defp expand_field(field) when is_binary(field) do
    expand_field(%{"name" => field})
  end

  defp expand_field(%{"name" => _} = field) do
    {optional, field} = Map.pop(field, "optional", false)

    %{"alternatives" => [field], "optional" => optional}
  end

  defp expand_field(%{"alternatives" => _, "optional" => optional} = field)
       when not is_boolean(optional) do
    field
    |> Map.put("optional", false)
    |> expand_field()
  end

  defp expand_field(%{"alternatives" => alternatives} = field) do
    alternatives =
      alternatives
      |> Enum.map(&expand_field_alternative/1)

    %{field | "alternatives" => alternatives}
  end

  defp expand_field_alternative(alt) when is_binary(alt) do
    %{"name" => alt}
  end

  defp expand_field_alternative(alt), do: alt

  @doc """
  Validate and then expand user input specification data.

  Returns `{:ok, attrs}` or `{:error, json_schema_errors}`.
  """
  def validate_and_expand(data) do
    case validate(data) do
      :ok ->
        {:ok, expand(data)}

      err ->
        err
    end
  end

  @doc """
  Reverses `expand`, so the full form data is compacted into the tersest equivalent
  syntax. Accepts and returns a map.

  ## Examples

      iex> attrs = %Spec{
        match: [
          %Match{
            alternatives: %MatchAlternative{
              path: %Path{
                schema: "public",
                table: "users"
              },
              fields: [
                %Field{
                  alternatives: [
                    %FieldAlternative{
                      name: "id"
                    }
                  ]
                },
                %Field{
                  alternatives: [
                    %FieldAlternative{
                      name: "uuid"
                    }
                  ]
                ]
              }
            }
          }
        ]
      }
      iex> contract(attrs)
      %{match: [%{path: "public.users", fields: ["id", "uuid"]}]}

  """

  def contract(%Spec{match: matches} = spec) do
    spec
    |> Map.from_struct()
    |> Map.put(:match, Enum.map(matches, &contract_match/1))
  end

  defp contract_match(%Match{alternatives: [match_alt], optional: optional}) do
    match_alt
    |> contract_match_alt()
    |> with_optional(optional)
  end

  defp contract_match(%Match{alternatives: match_alts} = match) do
    {optional, match_map} =
      match
      |> Map.from_struct()
      |> Map.pop(:optional)

    %{match_map | alternatives: Enum.map(match_alts, &contract_match_alt/1)}
    |> with_optional(optional)
  end

  defp contract_match_alt(%MatchAlternative{path: path, fields: fields}) do
    %{path: contract_path(path), fields: contract_fields(fields)}
  end

  defp contract_path(%Path{schema: schema, table: table}) do
    "#{schema}.#{table}"
  end

  defp contract_fields(fields) when is_list(fields) do
    fields
    |> Enum.map(&contract_field/1)
  end

  defp contract_field(%Field{alternatives: [field_alt], optional: optional}) do
    field_alt
    |> contract_field_alt(optional)
  end

  defp contract_field(%Field{alternatives: field_alts, optional: optional}) do
    %{alternatives: Enum.map(field_alts, &contract_field_alt_into_map/1)}
    |> with_optional(optional)
  end

  defp contract_field_alt(%FieldAlternative{} = field_alt, optional) do
    field_alt
    |> Map.from_struct()
    |> with_optional(optional)
    |> contract_field_alt()
  end

  defp contract_field_alt(field_alt_map) when is_map(field_alt_map) do
    filtered = filter_field_alt_map(field_alt_map)

    case Map.keys(filtered) do
      [:name] ->
        filtered.name

      _alt ->
        filtered
    end
  end

  defp contract_field_alt_into_map(%FieldAlternative{} = field_alt) do
    field_alt
    |> Map.from_struct()
    |> filter_field_alt_map()
  end

  defp filter_field_alt_map(field_alt_map) do
    field_alt_map
    |> Enum.reject(fn {k, _} -> k == :id end)
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp with_optional(map, optional) do
    case optional do
      true ->
        Map.put(map, :optional, true)

      false ->
        map
    end
  end
end
