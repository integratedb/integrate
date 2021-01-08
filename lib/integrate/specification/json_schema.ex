defmodule Integrate.Specification.JsonSchema do
  @moduledoc """
  Use a JSON Schema to validate `claims` and `notifications` data provided
  as user input and stored as spec documents.
  """

  alias ExJsonSchema.{
    Schema,
    Validator
  }

  @schema
  :integrate
  |> :code.priv_dir()
  |> Path.join("spec.schema.json")
  |> File.read!()
  |> Jason.decode!()
  |> Schema.resolve()

  def validate(data) do
    Validator.validate(@schema, data)
  end
end
