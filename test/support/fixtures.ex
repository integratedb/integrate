defmodule Integrate.Fixtures do
  @moduledoc """
  Test fixtures.
  """
  use Integrate, :contexts

  def create_user(_) do
    attrs = %{
      username: "root",
      password: "1234567890"
    }

    {:ok, user} = Accounts.create_user(attrs)

    %{user: user}
  end

  def create_stakeholder(%{user: user}) do
    attrs = %{
      name: "reporter"
    }

    {:ok, %{stakeholder: stakeholder, db_user: db_user}} =
      Stakeholders.create_stakeholder(user, attrs)

    %{stakeholder: stakeholder, stakeholder_db_user: db_user}
  end

  def create_spec(%{stakeholder: stakeholder}) do
    attrs = %{
      type: "CLAIMS",
      match: []
    }

    {:ok, spec} = Specification.create_spec(stakeholder, attrs)

    %{spec: spec}
  end

  def create_claim(%{spec: spec}) do
    attrs = %{}

    {:ok, claim} = Claims.create_claim(spec, attrs)

    %{claim: claim}
  end

  def create_claim_alternative(%{claim: claim}) do
    attrs = %{
      schema: "public",
      table: "foo"
    }

    {:ok, claim_alt} = Claims.create_claim_alternative(claim, attrs)

    %{claim_alternative: claim_alt}
  end

  def create_column(%{claim_alternative: claim_alternative}) do
    attrs = %{}

    {:ok, column} = Claims.create_column(claim_alternative, attrs)

    %{column: column}
  end
end
