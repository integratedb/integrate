defmodule IntegrateWeb.SpecificationData do
  @moduledoc """
  Validate and transform specification data.
  """

  alias Integrate.Specification.{
    Spec,
    Match,
    Path,
    Field,
    Cell
  }

  alias IntegrateWeb.JsonSchema

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
    JsonSchema.validate("spec.schema.json", patch(data))
  end

  # XXX Fix me.
  # Our `spec.schema.json` JSON schema currently fails to allow an empty fields array
  # like `fields: []`. This is a natural syntax for a user to write, so in lieu of better
  # schema foo, workaround for now by patching the input data.
  defp patch(%{"match" => matches} = data) when is_list(matches) do
    %{data | "match" => Enum.map(matches, &patch_fields/1)}
  end

  defp patch(data), do: data

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
            "path": %{
              "alternatives" ["public.users"]
            },
            "fields": [
              %{"alternatives" [%{"name": "id"}]},
              %{"alternatives" [%{"name": "uuid"}]}
            }
          }
        ]
      }

  """
  def expand(%{"match" => matches} = data) do
    matches = Enum.map(matches, &expand_match/1)

    %{data | "match" => matches}
  end

  defp expand_match(match) when not is_map_key(match, "fields") do
    match
    |> Map.put_new("fields", [])
    |> expand_match()
  end

  defp expand_match(%{"fields" => nil} = match) do
    %{match | "fields" => []}
    |> expand_match()
  end

  defp expand_match(%{"path" => path, "fields" => fields} = match) do
    %{match | "path" => expand_path(path), "fields" => expand_fields(fields)}
  end

  # path: "public.*",
  # path: "public.foo"
  # path: ["public.*"],
  # path: ["public.foo", "public.bar"]

  defp expand_path(path) when is_binary(path) do
    expand_path([path])
  end

  defp expand_path(path) when is_list(path) do
    %{"alternatives" => path}
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

  defp expand_field(%{"alternatives" => _} = field) when not is_map_key(field, "optional") do
    field
    |> Map.put_new("optional", false)
  end

  defp expand_field(%{"alternatives" => _, "optional" => _} = field), do: field

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

      iex> attrs = %{
        match: [
          %{
            path: %{
              alternatives: ["public.users"]
            },
            fields: %{
              alternatives: [
                %{name: "id"},
                %{name: "uuid"}
              ]
            }
          }
        ]
      }
      iex> contract(attrs)
      %{"match": [%{path" => "public.users", "fields" => ["id", "uuid"]}]}

  """

  def contract(%Spec{match: matches} = data) do
    matches = Enum.map(matches, &contract_match/1)

    %{data | match: matches}
  end

  defp contract_match(%Match{path: path, fields: fields} = match) do
    %{match | path: contract_path(path), fields: contract_fields(fields)}
  end

  defp contract_path(%Path{alternatives: [path]}) do
    path
  end

  defp contract_path(%Path{alternatives: paths}) do
    paths
  end

  defp contract_fields(fields) when is_list(fields) do
    fields
    |> Enum.map(&contract_field/1)
  end

  defp contract_field(%Field{alternatives: [cell], optional: optional}) do
    cell
    |> contract_cell(optional)
  end

  defp contract_field(%Field{alternatives: cells, optional: true}) do
    %{alternatives: Enum.map(cells, &contract_cell_into_map/1), optional: true}
  end

  defp contract_field(%Field{alternatives: cells, optional: false}) do
    %{alternatives: Enum.map(cells, &contract_cell_into_map/1)}
  end

  defp contract_cell(%Cell{} = cell, true) do
    cell
    |> Map.from_struct()
    |> Map.put(:optional, true)
    |> contract_cell()
  end

  defp contract_cell(%Cell{} = cell, false) do
    cell
    |> Map.from_struct()
    |> contract_cell()
  end

  defp contract_cell(cellmap) when is_map(cellmap) do
    filtered = filter_cellmap(cellmap)

    case Map.keys(filtered) do
      [:name] ->
        filtered.name

      _alt ->
        filtered
    end
  end

  defp contract_cell_into_map(%Cell{} = cell) do
    cell
    |> Map.from_struct()
    |> filter_cellmap()
  end

  defp filter_cellmap(cellmap) do
    cellmap
    |> Enum.reject(fn {k, _} -> k == :id end)
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end
end
