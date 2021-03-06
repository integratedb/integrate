defmodule Integrate.Config do
  @moduledoc """
  Config helpers.
  """

  alias Integrate.Validate

  def namespace do
    :integratedb
    |> Application.fetch_env!(:db_namespace)
    |> Validate.validate_and_downcase_namespace()
  end
end
