defmodule IntegrateWeb.SpecificationData do
  @moduledoc """
  Validate and transform specification data.
  """

  alias ExJsonSchema.{
    Schema,
    Validator
  }

  @schema :code.priv_dir(:integrate)
    |> Path.join("spec.schema.json")
    |> File.read!()
    |> Jason.decode!()
    |> Schema.resolve()

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
    Validator.validate(@schema, data)
  end

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
            "fields": %{
              "alternatives" [
                %{"name": "id"},
                %{"name": "uuid"}
              ]
            }
          }
        ]
      }

  """
  def expand(data) do
    throw {:NotImplemented, :expand, data}
  end

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
  def contract(attrs) do
    throw {:NotImplemented, :contract, attrs}
  end
end
