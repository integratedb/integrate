defmodule Integrate do
  @moduledoc """
  Integrate keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def contexts do
    quote do
      alias Integrate.Accounts
      alias Integrate.Claims
      alias Integrate.Specification
      alias Integrate.Stakeholders
    end
  end

  def schema do
    quote do
      use Ecto.Schema
      use Integrate, :contexts

      alias Integrate.Validate

      import Ecto.Changeset

      @timestamps_opts [type: :utc_datetime_usec]
      @schema_prefix Integrate.Config.namespace()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
