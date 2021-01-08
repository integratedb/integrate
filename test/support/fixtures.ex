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
end
