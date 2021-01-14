defmodule IntegrateWeb.JsonSchema do
  @moduledoc """
  Resolve and load json schemas for use with `ExJsonSchema`.
  """
  use Memoize

  alias ExJsonSchema.{
    Schema,
    Validator
  }

  defmemo load(name) do
    name
    |> read_and_decode()
    |> Schema.resolve()
  end

  def validate(name, data) do
    name
    |> load()
    |> Validator.validate(data)
  end

  defp read_and_decode(name) do
    parts = [
      :code.priv_dir(:integrate),
      "spec",
      name
    ]

    parts
    |> Path.join()
    |> File.read!()
    |> Jason.decode!()
  end
end
